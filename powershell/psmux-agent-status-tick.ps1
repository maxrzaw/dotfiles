#!/usr/bin/env pwsh
# psmux-agent-status-tick.ps1 — one-shot status refresh, fired by psmux hooks.
#
# psmux.conf runs this on every server's status-interval. No persistent process:
# if a tick fails, the next interval fires anyway.
#
# Each interval, a mutex elects one tick to do the expensive scan (age-gated so
# staggered per-server firings don't all rescan). Whenever a tick scans, it fans
# the roll-up out to every server via -t — necessary because status-interval does
# NOT fire on every server (detached / full-screen-TUI servers can go silent), so
# one firing server must refresh them all. Each tick also self-publishes to its
# own server from the snapshot; if the snapshot is too stale, it self-hides.
#
# The scan/classify/publish helpers live in psmux-agent-status.ps1 (sourced below).

$ErrorActionPreference = 'SilentlyContinue'

# Force UTF-8: a -NoProfile pwsh otherwise garbles the glyphs and the icon-tagged
# names read back via list-panes, making capture/rename miss.
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::InputEncoding  = [Text.Encoding]::UTF8
$OutputEncoding           = [Text.Encoding]::UTF8

# A hook child inherits PSMUX_TARGET_SESSION set to its own server — leave it, the
# no-`-t` self-publish depends on it. Bail if that server is a warm standby.
if ($env:PSMUX_TARGET_SESSION -match '__warm__$') { return }

$intervalSeconds = 5
$rescanIfOlder   = $intervalSeconds / 2.0     # don't rescan a snapshot newer than this
$staleAfter      = $intervalSeconds * 3.0     # older than this = feed is dead, self-hide

. (Join-Path $PSScriptRoot 'psmux-agent-status.ps1')

# Elect one scanner. Non-blocking: losers skip the scan. An abandoned mutex (owner
# killed mid-scan) transfers to us.
$mutex = New-Object System.Threading.Mutex($false, 'Local\psmux-agent-status-tick')
$haveLock = $false
try { $haveLock = $mutex.WaitOne(0) }
catch [System.Threading.AbandonedMutexException] { $haveLock = $true }

$snap = $null
$didScan = $false
if ($haveLock) {
    try {
        Invoke-OrphanSweep                    # once per run; strips stale leftover tags
        $existing = Read-StatusSnapshot
        if ((Get-SnapshotAgeSeconds $existing) -ge $rescanIfOlder) {
            $snap = Invoke-AgentScan
            $didScan = $true
        } else {
            $snap = $existing                 # fresh enough; reuse
        }
    } finally {
        try { $mutex.ReleaseMutex() } catch {}
        $mutex.Dispose()
    }
} else {
    $mutex.Dispose()
    $snap = Read-StatusSnapshot
}

# On a fresh scan, fan out to every server (some never tick on their own). Only on
# a fresh scan, so stale data is never propagated.
if ($didScan) {
    if ($snap -and $snap.rollup) { Publish-AgentStatusAll -Rollup $snap.rollup }
    else { Clear-AgentStatusAll }
}

# Refresh this server from the snapshot; self-hide if it's too stale to trust.
$age = Get-SnapshotAgeSeconds $snap
if ($snap -and $age -lt $staleAfter -and $snap.rollup) {
    Publish-AgentStatusSelf -Rollup $snap.rollup
} else {
    Hide-AgentStatusSelf
}
