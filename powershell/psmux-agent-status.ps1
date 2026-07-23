# psmux-agent-status.ps1 — agent-state visibility for psmux.
#
# Reads each `claude` pane's bottom buffer via `psmux capture-pane`, classifies
# its state from the on-screen text, then tags the claude window with a state
# icon and publishes a roll-up of every session's state into the @agent_status
# option (status-right reads it via #{?@agent_status,...,}). No Claude hooks
# required — detection is pure screen-scraping.
#
# Classification is tied to Claude's current TUI text; a big UI redesign may need
# a regex tweak. idle/working detect reliably; "blocked" can lag a few seconds.
#
# Usage:
#   Start-AgentStatus            # poll every 5s until Ctrl+C
#   Start-AgentStatus -Once      # single pass
#   Start-AgentStatus -IntervalSeconds 2

# State -> status-bar glyph.
$script:AgentIcons = [ordered]@{
    working = '●'   # generating / running a tool
    blocked = '◍'   # waiting for the user (permission prompt, selection form)
    idle    = '✓'   # prompt ready, nothing pending
    none    = ''    # no claude pane — bare name, no glyph
    unknown = '·'   # transient UI (transcript, model picker) — hold last state
}

# Classify one captured screen. Evaluated highest-priority-first so a permission
# prompt is never misread as idle just because a "❯" is on screen.
function Get-AgentState {
    param([string[]]$Lines)

    if (-not $Lines -or $Lines.Count -eq 0) { return 'unknown' }

    $ne   = $Lines | Where-Object { $_.Trim() }
    $tail = ($ne | Select-Object -Last 12)
    $blob = ($tail -join "`n")
    $low  = $blob.ToLowerInvariant()

    # WORKING: a spinner glyph is not enough — a finished turn leaves a past-tense
    # summary ("✻ Crunched for 4s") that starts with the same glyph but is idle.
    # Require the glyph AND a live-activity marker (elapsed timer, token count, or
    # "esc to interrupt") on the same line, and exclude the "<Verb> for Ns" summary.
    foreach ($l in $tail) {
        $glyph = $l -match '^\s*[⠀-⣿✳✴✻✼✽✹✤]\s?\S'
        if ($glyph) {
            $liveActivity = ($l -match '\(\s*\d+s\b') -or
                            ($l -match '·\s*\d') -or
                            ($l -match 'esc to interrupt') -or
                            ($l -match 'token')
            $finishedSummary = $l -match '(?i)^\s*[⠀-⣿✳✴✻✼✽✹✤]\s+\w+\s+for\s+\d+s\s*$'
            if ($liveActivity -and -not $finishedSummary) { return 'working' }
        }
    }
    # Live-activity line with the spinner scrolled off (not the bare "esc to
    # interrupt" footer, which also shows when idle).
    if ($low -match '\d+s\s*·[^\n]*token') { return 'working' }

    # UNKNOWN: transient full-screen UI — hold the previous state, don't overwrite.
    if ($low -match 'showing detailed transcript') { return 'unknown' }
    if ($low -match 'select model' -and $low -match 'esc to cancel' -and $low -notmatch 'do you want to proceed') { return 'unknown' }

    # BLOCKED: selection menu.
    if (($low -match 'enter to select' -or $low -match 'esc to cancel') -and
        ($low -match 'to navigate' -or $low -match 'arrow keys')) { return 'blocked' }
    if ($low -match 'run a dynamic workflow\?' -and $low -match 'esc to cancel') { return 'blocked' }

    # capture-pane collapses spaces in some rendered lines ("Do you wanttoproceed?",
    # "❯1. Yes"). $sp makes a phrase space-tolerant: "do you want to" -> "do\s*you\s*want\s*to".
    $sp = { param($phrase) ($phrase -split ' ' | ForEach-Object { [regex]::Escape($_) }) -join '\s*' }

    # Numbered permission menu (❯1. Yes / 2. No) — strongest signal, survives the
    # space-collapsing above.
    foreach ($l in $tail) {
        if ($l -match '(?i)^\s*❯?\s*\d+\.\s*yes\b' -or $l -match '(?i)^\s*\d+\.\s*no\b') { return 'blocked' }
    }
    if ($low -match (& $sp 'do you want to proceed')) { return 'blocked' }
    if (($low -match (& $sp 'enter to select') -or $low -match (& $sp 'esc to cancel')) -and
        ($low -match (& $sp 'to navigate') -or $low -match (& $sp 'arrow keys'))) { return 'blocked' }
    if ($low -match (& $sp 'run a dynamic workflow') -and $low -match (& $sp 'esc to cancel')) { return 'blocked' }

    # An empty "❯" box means the turn is done and Claude awaits free input (idle),
    # not a yes/no question. It vetoes the loose blocker below so ordinary prose
    # ("What would you like to work on?") isn't misread as blocked. A real menu
    # already returned 'blocked' above.
    $emptyPromptBox = [bool]($tail | Where-Object { $_ -match '^\s*❯\s*$' })
    if (-not $emptyPromptBox) {
        if (($low -match (& $sp 'do you want to') -or $low -match (& $sp 'would you like to')) -and
            ($low -match 'yes' -or $blob -match '❯')) { return 'blocked' }
    }
    if ($low -match (& $sp 'waiting for permission'))  { return 'blocked' }
    # Amend/explain affordances only appear under a permission prompt.
    if ($low -match (& $sp 'tab to amend') -or $low -match (& $sp 'ctrl+e to explain')) { return 'blocked' }
    if (-not $emptyPromptBox -and $low -match (& $sp 'esc to cancel')) { return 'blocked' }

    # IDLE: a "❯" line with no menu/prompt text around it.
    foreach ($l in $tail) {
        if ($l -match '^\s*❯') {
            if ($low -notmatch 'enter to select' -and $low -notmatch 'esc to cancel' -and
                $low -notmatch 'to navigate' -and $low -notmatch 'arrow keys') { return 'idle' }
        }
    }

    return 'unknown'
}

# Panes whose foreground process is claude. window_name is included (and placed
# LAST, so a name containing '|' can't shift earlier fields) to avoid a separate
# per-pane display-message call. Match the COMMAND field, not a window NAMED claude.
function Get-ClaudePanes {
    psmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{session_name}|#{window_index}|#{pane_current_command}|#{window_name}" 2>$null |
        ForEach-Object { ,($_ -split '\|', 5) } |
        Where-Object { $_.Count -eq 5 -and $_[3] -eq 'claude' } |
        ForEach-Object {
            [pscustomobject]@{
                Target     = $_[0]
                Session    = $_[1]
                Window     = $_[2]
                WindowName = $_[4]
            }
        }
}

# Last non-transient state per pane, so 'unknown' holds the previous meaningful
# state instead of flapping. (Only persists within one process.)
$script:LastState = @{}

# Icon character class, for stripping a previously-applied icon so re-tagging is
# idempotent (never "● ● name").
$script:IconClass = '[' + (($script:AgentIcons.Values | ForEach-Object { [regex]::Escape($_) }) -join '') + ']'

# Strip a leading "<icon> " tag to recover the base name.
function Get-BaseName {
    param([string]$Name)
    ($Name -replace "^\s*$($script:IconClass)\s+", '').Trim()
}

# Roll-up separator. `set -g @option` keeps spaces in the value, so a readable
# " · " is fine here.
$script:RollupSep = ' ' + [char]0x00B7 + ' '

# Sidecar files, alongside psmux's own registry.
$script:StatusDir     = Join-Path $HOME '.psmux\status'
# Windows we renamed -> their original name, so tags can always be reverted even
# after a crash.
$script:TagManifest   = Join-Path $script:StatusDir 'window-tags.json'
# Snapshot for other consumers and for ticks to publish from.
$script:StatusJson    = Join-Path $script:StatusDir 'agent-status.json'
# Present = the once-per-run orphan-tag sweep has already happened.
$script:SweepMarker   = Join-Path $env:TEMP 'psmux-agent-status.swept'

function Ensure-StatusDir {
    if (-not (Test-Path $script:StatusDir)) {
        New-Item -ItemType Directory -Force -Path $script:StatusDir -ErrorAction SilentlyContinue | Out-Null
    }
}

# Atomic write: temp file then Move-Item -Force.
function Write-JsonAtomic {
    param([string]$Path, $Object)
    Ensure-StatusDir
    $tmp = "$Path.tmp"
    ($Object | ConvertTo-Json -Depth 6) | Set-Content -Path $tmp -Encoding utf8
    Move-Item -Path $tmp -Destination $Path -Force -ErrorAction SilentlyContinue
}

function Read-TagManifest {
    if (-not (Test-Path $script:TagManifest)) { return @{} }
    try {
        $obj = Get-Content $script:TagManifest -Raw -ErrorAction Stop | ConvertFrom-Json
        $h = @{}
        foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = $p.Value }
        return $h
    } catch { return @{} }
}

# Parsed snapshot, or $null if missing/unreadable.
function Read-StatusSnapshot {
    if (-not (Test-Path $script:StatusJson)) { return $null }
    try { return (Get-Content $script:StatusJson -Raw -ErrorAction Stop | ConvertFrom-Json) }
    catch { return $null }
}

# Snapshot age in seconds; MaxValue (treated as infinitely stale) if unparseable.
function Get-SnapshotAgeSeconds {
    param($Snapshot)
    if (-not $Snapshot -or -not $Snapshot.updated) { return [double]::MaxValue }
    try {
        $t = [datetimeoffset]::Parse($Snapshot.updated)
        return ([datetimeoffset]::Now - $t).TotalSeconds
    } catch { return [double]::MaxValue }
}

# Publish the roll-up to THIS server only (no -t; a hook child inherits its own
# server via PSMUX_TARGET_SESSION). The option name must be single-quoted — a bare
# @token is PowerShell splatting and expands to nothing.
function Publish-AgentStatusSelf {
    param([string]$Rollup)
    psmux set -g '@agent_status' $Rollup 2>$null | Out-Null
}

# Drop this server's segment (bar reverts to the themed default). Used when the
# snapshot is too stale to trust.
function Hide-AgentStatusSelf {
    psmux set -g -u '@agent_status' 2>$null | Out-Null
}

# Capture + classify every claude pane, tag windows, build the roll-up, write the
# snapshot. Does NOT publish @agent_status (the caller does). Returns the snapshot.
function Invoke-AgentScan {
    $panes = @(Get-ClaudePanes)

    # A session with any blocked pane sorts as blocked (attention-first). `none`
    # is lowest so any real pane outranks the no-agent baseline.
    $rank = @{ blocked = 3; working = 2; idle = 1; unknown = 0; none = -1 }

    $sessionState = [ordered]@{}   # session -> most-urgent state
    $sessionBase  = @{}            # session -> base name
    $paneStates   = [ordered]@{}   # pane target -> state
    $manifest     = @{}            # window target -> original name (this pass)
    # Previous pass's manifest, from disk (state doesn't survive across ticks).
    # A target here that isn't a claude pane now has had its claude exit.
    $prevManifest = Read-TagManifest

    # We deliberately never rename SESSIONS — that mutates psmux's registry
    # filenames and is fragile. Only windows get icon tags.
    foreach ($pane in $panes) {
        $cap   = psmux capture-pane -t $pane.Target -p 2>$null
        $state = Get-AgentState -Lines @($cap)

        if ($state -eq 'unknown' -and $script:LastState.ContainsKey($pane.Target)) {
            $state = $script:LastState[$pane.Target]
        } else {
            $script:LastState[$pane.Target] = $state
        }
        $paneStates[$pane.Target] = $state

        # Tag the window "<icon> <original>", recording the original for revert.
        $winTarget = "$($pane.Session):$($pane.Window)"
        $curName   = $pane.WindowName
        $orig      = Get-BaseName $curName
        # Skip if the base name is empty — a bare "<icon> " can't be stripped later.
        if ($orig) {
            $manifest[$winTarget] = $orig
            $desired = "$($script:AgentIcons[$state]) $orig"
            if ($curName -ne $desired) {   # skip the rename call when already correct
                psmux rename-window -t $winTarget $desired 2>$null | Out-Null
            }
        }

        if (-not $sessionBase.ContainsKey($pane.Session)) {
            $sessionBase[$pane.Session]  = Get-BaseName $pane.Session
            $sessionState[$pane.Session] = $state
        } elseif ($rank[$state] -gt $rank[$sessionState[$pane.Session]]) {
            $sessionState[$pane.Session] = $state
        }
    }

    # Revert windows whose claude exited since last pass (present before, gone now).
    foreach ($target in $prevManifest.Keys) {
        if (-not $manifest.ContainsKey($target)) {
            $origName = $prevManifest[$target]
            if ($origName) { psmux rename-window -t $target $origName 2>$null | Out-Null }
        }
    }

    Write-JsonAtomic -Path $script:TagManifest -Object $manifest

    # Fold in EVERY session so the roll-up lists them all; ones with no claude pane
    # get state 'none' (bare name). list-sessions order is preserved for a stable bar.
    $orderedState = [ordered]@{}
    foreach ($s in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $s) { continue }
        if ($sessionState.Contains($s)) {
            $orderedState[$s] = $sessionState[$s]
        } else {
            $orderedState[$s] = 'none'
            $sessionBase[$s]  = Get-BaseName $s
        }
    }
    $sessionState = $orderedState

    # "● dotfiles · ✓ test · scratch" — 'none' has an empty icon so those entries
    # are the bare name with no leading glyph/space.
    $rollupParts = foreach ($sess in $sessionState.Keys) {
        $icon = $script:AgentIcons[$sessionState[$sess]]
        $base = $sessionBase[$sess]
        if ($icon) { "$icon $base" } else { "$base" }
    }
    $rollup = $rollupParts -join $script:RollupSep

    $snap = [ordered]@{
        updated  = (Get-Date).ToString('o')
        rollup   = $rollup
        sessions = $sessionState
        panes    = $paneStates
    }
    Write-JsonAtomic -Path $script:StatusJson -Object $snap
    return $snap
}

# Publish the roll-up to EVERY server (options are per-server; each session is its
# own server). Space-named sessions are skipped (a space breaks the -t arg).
# Single-quote the option name (bare @token is PowerShell splatting).
function Publish-AgentStatusAll {
    param([string]$Rollup)
    foreach ($s in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $s) { continue }
        if ($s -match '\s') { continue }
        psmux set -g -t $s '@agent_status' $Rollup 2>$null | Out-Null
    }
}

# Unset the option on every server — for when a scan finds no claude panes at all,
# so every bar drops its segment instead of freezing on the last roll-up.
function Clear-AgentStatusAll {
    foreach ($s in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $s) { continue }
        if ($s -match '\s') { continue }
        psmux set -g -t $s -u '@agent_status' 2>$null | Out-Null
    }
}

# Persistent-poller path: scan + fan out to all servers.
function Update-AgentStatus {
    $snap = Invoke-AgentScan
    Publish-AgentStatusAll -Rollup $snap.rollup
}

# Single-instance guard for the persistent poller, via a PID marker file:
# "running" = marker exists and names a live pwsh process. A crash leaves a stale
# PID whose lookup fails, so the next start takes over. No cleanup needed.
$script:PollerPidFile = Join-Path $env:TEMP 'psmux-agent-status.pid'

# Live poller PID per the marker, or $null. Requires the process to be pwsh
# (guards against PID reuse).
function Get-RunningPollerPid {
    if (-not (Test-Path $script:PollerPidFile)) { return $null }
    $recorded = (Get-Content $script:PollerPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $recorded) { return $null }
    $procId = 0
    if (-not [int]::TryParse($recorded.Trim(), [ref]$procId)) { return $null }
    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($p -and $p.ProcessName -match '^pwsh') { return $procId }
    return $null
}

# Strip a leftover icon prefix from ANY window. Catches orphaned tags (icon but no
# matching manifest entry) that the per-pass revert can't see.
function Invoke-IconSweep {
    foreach ($line in @(psmux list-panes -a -F "#{session_name}:#{window_index}|#{window_name}" 2>$null)) {
        $parts = $line -split '\|', 2
        if ($parts.Count -eq 2) {
            $wbase = Get-BaseName $parts[1]
            if ($wbase -ne $parts[1]) { psmux rename-window -t $parts[0] $wbase 2>$null | Out-Null }
        }
    }
}

# Run the orphan sweep at most once per run (marker-guarded). Cheap to call every
# tick; the marker is cleared on a full restore so a fresh run sweeps again.
function Invoke-OrphanSweep {
    if (Test-Path $script:SweepMarker) { return }
    Invoke-IconSweep
    Set-Content -Path $script:SweepMarker -Value '1' -Encoding ascii -ErrorAction SilentlyContinue
}

# Revert everything: manifest-driven exact-name restore, a residual-icon sweep,
# and clear @agent_status on every server (the bar self-hides). No sessions to
# restore — we never rename them.
function Restore-AgentStatus {
    $manifest = Read-TagManifest
    foreach ($target in $manifest.Keys) {
        $orig = $manifest[$target]
        if ($orig) { psmux rename-window -t $target $orig 2>$null | Out-Null }
    }
    Invoke-IconSweep
    foreach ($sess in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $sess -or ($sess -match '\s')) { continue }
        psmux set -g -t $sess -u '@agent_status' 2>$null | Out-Null
    }
    Remove-Item $script:TagManifest -ErrorAction SilentlyContinue
    Remove-Item $script:SweepMarker  -ErrorAction SilentlyContinue
}

function Start-AgentStatus {
    [CmdletBinding()]
    param(
        [int]$IntervalSeconds = 5,
        [switch]$Once
    )
    # A shell can carry a stale PSMUX_SESSION (e.g. "__warm__") that routes the CLI
    # to the wrong socket, so -t writes land on a warm server. Clear it so -t
    # targets the real servers.
    Remove-Item Env:\PSMUX_SESSION        -ErrorAction SilentlyContinue
    Remove-Item Env:\PSMUX_TARGET_SESSION -ErrorAction SilentlyContinue

    if ($Once) { Update-AgentStatus; return }

    $running = Get-RunningPollerPid
    if ($running -and $running -ne $PID) {
        Write-Host "psmux agent-status: a poller is already running (PID $running); not starting another."
        return
    }
    Set-Content -Path $script:PollerPidFile -Value $PID -Encoding ascii
    # A previous poller may have died tagged; clean up before we tag anything.
    try { Restore-AgentStatus } catch { }
    Write-Host "psmux agent-status poller running (PID $PID, every ${IntervalSeconds}s). Ctrl+C to stop."
    # list-sessions returns empty transiently, so quit only after several
    # consecutive empties (real shutdown), and never die on a thrown update.
    $emptyStreak = 0
    $maxEmpty    = 6
    try {
        while ($true) {
            $alive = psmux list-sessions -F "#{session_name}" 2>$null
            if (-not $alive) {
                $emptyStreak++
                if ($emptyStreak -ge $maxEmpty) { break }
            } else {
                $emptyStreak = 0
                try { Update-AgentStatus } catch { }
            }
            # Yield if another poller claimed the marker; otherwise re-assert ours.
            if ((Get-Content $script:PollerPidFile -ErrorAction SilentlyContinue) -ne "$PID") {
                $other = Get-RunningPollerPid
                if ($other -and $other -ne $PID) { break }
                Set-Content -Path $script:PollerPidFile -Value $PID -Encoding ascii
            }
            Start-Sleep -Seconds $IntervalSeconds
        }
    } finally {
        try { Restore-AgentStatus } catch {}
        # Remove the marker only if it's still ours.
        if ((Get-RunningPollerPid) -eq $PID -or (Get-Content $script:PollerPidFile -ErrorAction SilentlyContinue) -eq "$PID") {
            Remove-Item $script:PollerPidFile -ErrorAction SilentlyContinue
        }
    }
}

# Detached, hidden, idempotent launcher. Repeated calls don't stack (PID guard);
# a crashed poller is replaced on the next call.
function Start-AgentStatusBackground {
    [CmdletBinding()]
    param([int]$IntervalSeconds = 5)

    if (Get-RunningPollerPid) { return }

    # Force UTF-8: a -NoProfile pwsh otherwise garbles the glyphs and the icon-
    # tagged session names it reads back, so -t targeting misses the real session.
    $script = $PSCommandPath
    $bootstrap = "[Console]::OutputEncoding=[Text.Encoding]::UTF8; " +
                 "[Console]::InputEncoding=[Text.Encoding]::UTF8; " +
                 "`$OutputEncoding=[Text.Encoding]::UTF8; " +
                 ". '$script'; Start-AgentStatus -IntervalSeconds $IntervalSeconds"
    Start-Process pwsh -WindowStyle Hidden -ArgumentList @(
        '-NoProfile','-NoLogo','-Command', $bootstrap
    ) | Out-Null
}

Set-Alias -Name agentstatus   -Value Start-AgentStatus           -Scope Global
Set-Alias -Name agentstatusbg -Value Start-AgentStatusBackground -Scope Global
