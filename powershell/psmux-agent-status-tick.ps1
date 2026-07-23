#!/usr/bin/env pwsh
# psmux-agent-status-tick.ps1 — ONE-SHOT tick for the hook-scheduled variant of
# the agent-status feature. Replaces the persistent background daemon.
# ---------------------------------------------------------------------------
# WHY THIS EXISTS: the persistent poller (Start-AgentStatusBackground) had a
# reliability problem — a detached pwsh process would sometimes die (or never
# survive a profile-launch race), and then the bar went blank with nothing to
# restart it. This tick is fired BY THE SERVER itself via psmux hooks:
#
#   set-hook -ga status-interval 'run-shell "pwsh -NoProfile -File .../psmux-agent-status-tick.ps1"'
#   set-hook -ga client-attached 'run-shell "pwsh -NoProfile -File .../psmux-agent-status-tick.ps1"'
#
# Every psmux server fires this every `status-interval` seconds (and on attach).
# There is NO daemon to die: if one tick fails, the next interval fires anyway.
#
# MODEL (plan task 4, model 2 + HYBRID -t sweep):
#   1. A named mutex elects ONE tick to run the EXPENSIVE scan (capture +
#      classify all claude panes, tag windows, write the JSON snapshot). Ticks
#      that lose the mutex skip the scan.
#   2. But the mutex only dedupes CONCURRENT ticks. Staggered firings across
#      servers (server A at t=0, server B at t=2s) each win their own window and
#      would each rescan. So the winner ALSO gates on snapshot age: it only
#      rescans if the snapshot is older than ~half the interval. Otherwise the
#      fresh snapshot stands.
#   3. HYBRID FAN-OUT: whenever a tick (re)scans, it ALSO publishes @agent_status
#      to EVERY server via -t (like the old daemon did). WHY: testing showed
#      status-interval does NOT fire uniformly across servers on this build — some
#      sessions' timers tick, others never do (correlated with attach/TUI state).
#      Relying on each server's own hook to self-publish left detached/TUI servers
#      permanently blank. The -t sweep means as long as ANY ONE server's hook
#      fires, every bar refreshes. This is the reliability fix the pure
#      self-publish model lacked.
#   4. Every tick ALSO self-publishes to its OWN server from the snapshot (no -t).
#      Redundant with the winner's -t sweep, but near-free and gives an attached
#      server an instant refresh the moment its client-attached hook fires.
#   5. If the snapshot is too stale (~3 intervals — the scanner has stopped), the
#      tick UNSETS its own @agent_status so the bar self-hides instead of freezing
#      on stale data (also per-server correctness, plan F1). The -t sweep only
#      runs on a FRESH scan, so it never propagates stale data.
#
# The heavy lifting (classify/scan/publish helpers) lives in
# psmux-agent-status.ps1, dot-sourced below and reused verbatim.
# See psmux-agent-status.TODO.md task 4.
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'SilentlyContinue'

# UTF-8 is mandatory: a -NoProfile pwsh defaults to a non-UTF-8 console encoding,
# which garbles the ●/◍/✓/· glyphs AND the icon-tagged session/window names read
# back via list-panes, making capture/rename miss. (Task 1's move to @ user
# options made the VALUE space-safe but did NOT remove this — the scan still reads
# names back.)
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::InputEncoding  = [Text.Encoding]::UTF8
$OutputEncoding           = [Text.Encoding]::UTF8

# ENV-VAR HANDLING for a server-spawned hook child (differs from the user-shell
# entry paths, per plan task 4):
#   - Do NOT clear PSMUX_TARGET_SESSION. The server PRESETS it to ITSELF on
#     purpose; it's what makes the no-`-t` own-server self-publish target the
#     right server. Clearing it would break model 2.
#   - Warm-server guard: warm standby servers pre-load config and can run
#     startup-spawned scripts, but hooks should not do real work on them. If we
#     were somehow spawned on a warm server, bail. (Hooks don't fire on warm
#     servers, but this is a cheap belt-and-suspenders.)
#   - PSMUX_SESSION is only consulted by the nesting warning on new-session/
#     attach, which this script never runs, so it needs no handling here.
if ($env:PSMUX_TARGET_SESSION -match '__warm__$') { return }

# Tunables. Interval matches status-interval (5s). Half-interval age gate avoids
# redundant staggered rescans; 3-interval staleness bound self-hides a dead feed.
$intervalSeconds = 5
$rescanIfOlder   = $intervalSeconds / 2.0     # ~2.5s
$staleAfter      = $intervalSeconds * 3.0     # ~15s

. (Join-Path $PSScriptRoot 'psmux-agent-status.ps1')

# --- Phase 1: maybe-scan (mutex + age gate) --------------------------------
# Non-blocking mutex election. Winner does the scan IF the snapshot is stale
# enough to warrant it; losers skip straight to self-publish. Abandoned-mutex
# (previous owner killed mid-scan) transfers ownership to us. Pattern from
# psmux-continuum/scripts/auto_save.ps1.
$mutex = New-Object System.Threading.Mutex($false, 'Local\psmux-agent-status-tick')
$haveLock = $false
try { $haveLock = $mutex.WaitOne(0) }
catch [System.Threading.AbandonedMutexException] { $haveLock = $true }

$snap = $null
$didScan = $false
if ($haveLock) {
    try {
        $existing = Read-StatusSnapshot
        if ((Get-SnapshotAgeSeconds $existing) -ge $rescanIfOlder) {
            $snap = Invoke-AgentScan          # expensive pass; refreshes the snapshot
            $didScan = $true
        } else {
            $snap = $existing                 # fresh enough; reuse it
        }
    } finally {
        try { $mutex.ReleaseMutex() } catch {}
        $mutex.Dispose()
    }
} else {
    $mutex.Dispose()
    $snap = Read-StatusSnapshot               # loser: just read the shared snapshot
}

# --- Phase 2a: HYBRID -t fan-out (only on a fresh scan) --------------------
# status-interval doesn't fire on every server, so the tick that DID scan pushes
# the fresh roll-up to ALL servers via -t. This is what makes non-ticking servers
# (detached / in a full-screen TUI) refresh. Only runs on a fresh scan, so it
# never propagates stale data. Empty rollup (no claude panes) → clear all.
if ($didScan) {
    if ($snap -and $snap.rollup) { Publish-AgentStatusAll -Rollup $snap.rollup }
    else { Clear-AgentStatusAll }
}

# --- Phase 2b: self-publish or self-hide (this server only, no -t) ---------
# Redundant with the sweep after a fresh scan, but near-free and gives this
# server an instant refresh when its own (e.g. client-attached) hook fires
# between scans.
$age = Get-SnapshotAgeSeconds $snap
if ($snap -and $age -lt $staleAfter -and $snap.rollup) {
    Publish-AgentStatusSelf -Rollup $snap.rollup
} else {
    # No snapshot, too stale, or empty roll-up (no claude panes anywhere) —
    # drop our segment so the bar reverts to the themed default.
    Hide-AgentStatusSelf
}
