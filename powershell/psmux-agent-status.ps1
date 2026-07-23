# psmux-agent-status.ps1 — herdr-style agent-state visibility for psmux.
# ---------------------------------------------------------------------------
# Background poller that reads each `claude` pane's bottom-buffer (via
# `psmux capture-pane`) and classifies its state by matching against a
# text-only port of herdr's Claude detection manifest. It then:
#   1. renames the claude window with a state icon (per-session visibility), and
#   2. writes a roll-up of every claude session's state into the @agent_status
#      user option, which status-right reads via #{?@agent_status,...,}.
#
# WHY THIS EXISTS: herdr detects Claude state WITHOUT hooks — it screen-scrapes
# the pane's bottom buffer and applies TOML "agent-detection manifests". This
# machine has Claude hooks disabled org-wide (allowManagedHooksOnly + empty
# managed hooks), but scraping needs no hooks, so herdr's real technique still
# works here. This is a faithful subset of herdr's own manifest (v2026.07.13.1),
# limited to its screen-text rules — the OSC-title/progress rules are dropped
# because psmux's pane_title does not surface Claude's title escape.
#
# LIMITATIONS (same shape as herdr's own docs):
#   - idle/working detect reliably; "blocked" can lag a few seconds.
#   - rules are tied to Claude's current TUI text; a big UI redesign may need a
#     regex tweak (a few lines, not a rebuild).
#
# USAGE:
#   Start-AgentStatus            # poll every 5s until stopped (Ctrl+C)
#   Start-AgentStatus -Once      # single pass (for testing)
#   Start-AgentStatus -IntervalSeconds 2
# ---------------------------------------------------------------------------

# State -> display icon. Kept ASCII-safe-ish; these are Nerd/Unicode glyphs that
# render in the psmux status bar (same font that draws the powerline theme).
$script:AgentIcons = [ordered]@{
    working = '●'   # actively generating / running a tool
    blocked = '◍'   # waiting for YOU (permission prompt, selection form)
    idle    = '✓'   # prompt box ready, nothing pending
    none    = ''    # session has NO claude pane — shown as bare name, no glyph
    unknown = '·'   # transient UI (transcript viewer, model picker) — hold last
}

# Classify one captured screen (array of lines, already bottom-of-buffer).
# Ported from herdr's manifest, evaluated HIGHEST-PRIORITY-FIRST so a permission
# prompt is never misread as idle just because a "❯" is on screen.
function Get-AgentState {
    param([string[]]$Lines)

    if (-not $Lines -or $Lines.Count -eq 0) { return 'unknown' }

    # Work on the last non-empty lines (herdr's "bottom_non_empty_lines" /
    # "after_last_horizontal_rule" regions approximated as a small tail window).
    $ne   = $Lines | Where-Object { $_.Trim() }
    $tail = ($ne | Select-Object -Last 12)
    $blob = ($tail -join "`n")
    $low  = $blob.ToLowerInvariant()

    # --- priority 1100/975: WORKING (LIVE spinner only) ----------------------
    # CAREFUL: a spinner glyph alone is NOT proof of working. When a turn
    # FINISHES, Claude leaves a past-tense summary line on screen like
    #   "✻ Crunched for 4s"   /   "✻ Churned for 2s"
    # which starts with the same glyph but is IDLE. Matching the bare glyph made
    # finished panes read as "working" forever (the "never goes idle" bug,
    # reproduced on stable idle panes dotfiles:5 and test).
    #
    # A LIVE spinner has a present-progressive ACTIVITY indicator on the SAME
    # line: a parenthetical elapsed timer "(4s · …)", a token count, or the
    # "esc to interrupt" affordance. The finished summary "✻ <Verb> for Ns" has
    # NONE of those. Require glyph + live-activity together.
    foreach ($l in $tail) {
        $glyph = $l -match '^\s*[⠀-⣿✳✴✻✼✽✹✤]\s?\S'
        if ($glyph) {
            $liveActivity = ($l -match '\(\s*\d+s\b') -or       # "(4s · ↓ 2.3k tokens)"
                            ($l -match '·\s*\d') -or            # "(… · 325 tokens)"
                            ($l -match 'esc to interrupt') -or
                            ($l -match 'token')
            $finishedSummary = $l -match '(?i)^\s*[⠀-⣿✳✴✻✼✽✹✤]\s+\w+\s+for\s+\d+s\s*$'  # "✻ Crunched for 4s"
            if ($liveActivity -and -not $finishedSummary) { return 'working' }
        }
    }
    # A standalone live-activity line (spinner scrolled off) — still not the bare
    # "esc to interrupt" footer, which the idle manual-mode bar also shows.
    if ($low -match '\d+s\s*·[^\n]*token') { return 'working' }

    # --- priority 1000/900: UNKNOWN (transient UI — do not overwrite state) ---
    # herdr's transcript_viewer / model_picker_menu set skip_state_update.
    if ($low -match 'showing detailed transcript') { return 'unknown' }
    if ($low -match 'select model' -and $low -match 'esc to cancel' -and $low -notmatch 'do you want to proceed') { return 'unknown' }

    # --- priority 980/850/840/300: BLOCKED (waiting for the user) ------------
    # live_blocked_form: selection menu.
    if (($low -match 'enter to select' -or $low -match 'esc to cancel') -and
        ($low -match 'to navigate' -or $low -match 'arrow keys')) { return 'blocked' }
    # dynamic_workflow_prompt.
    if ($low -match 'run a dynamic workflow\?' -and $low -match 'esc to cancel') { return 'blocked' }
    # IMPORTANT: psmux capture-pane COLLAPSES SPACES in some rendered lines
    # (observed: "Do you wanttoproceed?", "❯1. Yes", "Esc to cancel · Tab to amend").
    # So phrase rules must tolerate missing inter-word spaces. `$sp` builds a
    # space-optional version of a phrase: "do you want to" -> "do\s*you\s*want\s*to".
    $sp = { param($phrase) ($phrase -split ' ' | ForEach-Object { [regex]::Escape($_) }) -join '\s*' }

    # Strongest signal, and it SURVIVES space-collapsing: Claude's numbered
    # permission menu (❯1. Yes / 1. Yes / 2. No / 3. No). herdr's bash/generic
    # permission_prompt keys on this menu shape; we lead with it.
    foreach ($l in $tail) {
        if ($l -match '(?i)^\s*❯?\s*\d+\.\s*yes\b' -or $l -match '(?i)^\s*\d+\.\s*no\b') { return 'blocked' }
    }
    # "do you want to proceed?" (space-tolerant) — the canonical permission line.
    if ($low -match (& $sp 'do you want to proceed')) { return 'blocked' }
    # live_blocked_form / selection menus: navigate + select/cancel affordances.
    if (($low -match (& $sp 'enter to select') -or $low -match (& $sp 'esc to cancel')) -and
        ($low -match (& $sp 'to navigate') -or $low -match (& $sp 'arrow keys'))) { return 'blocked' }
    # dynamic_workflow_prompt.
    if ($low -match (& $sp 'run a dynamic workflow') -and $low -match (& $sp 'esc to cancel')) { return 'blocked' }

    # EMPTY PROMPT BOX veto — herdr's legacy_no_prompt_blocker has a `not` guard
    # for an empty "❯" line, which we must honor. An empty prompt box means the
    # turn is DONE and Claude is waiting for free input (idle), NOT asking a
    # yes/no question. Without this, Claude's own conversational output — e.g.
    # "What would you like to work on?" — false-matched the loose "would you like
    # to" + ❯ blocker and pinned an idle pane as blocked (reproduced on
    # dotfiles:5). If a real permission menu were up we'd already have returned
    # 'blocked' above (numbered menu / "do you want to proceed?"), so reaching
    # here with an empty ❯ box means idle.
    $emptyPromptBox = [bool]($tail | Where-Object { $_ -match '^\s*❯\s*$' })
    if (-not $emptyPromptBox) {
        # legacy_no_prompt_blocker: broad "do you want to / would you like to … yes/❯".
        # ONLY when there's no empty prompt box (per herdr's `not` guard).
        if (($low -match (& $sp 'do you want to') -or $low -match (& $sp 'would you like to')) -and
            ($low -match 'yes' -or $blob -match '❯')) { return 'blocked' }
    }
    if ($low -match (& $sp 'waiting for permission'))  { return 'blocked' }
    # Amend/explain affordances only appear under a real permission prompt.
    if ($low -match (& $sp 'tab to amend') -or $low -match (& $sp 'ctrl+e to explain')) { return 'blocked' }
    # Bare "esc to cancel" as a last-resort blocker cue — but not when an empty
    # prompt box is showing (that's idle, cancel hint is just the footer).
    if (-not $emptyPromptBox -and $low -match (& $sp 'esc to cancel')) { return 'blocked' }

    # --- priority 950: IDLE (live prompt box, nothing pending) ---------------
    # herdr live_prompt_box: a "❯" line, guarded against menu/prompt text.
    foreach ($l in $tail) {
        if ($l -match '^\s*❯') {
            if ($low -notmatch 'enter to select' -and $low -notmatch 'esc to cancel' -and
                $low -notmatch 'to navigate' -and $low -notmatch 'arrow keys') { return 'idle' }
        }
    }

    return 'unknown'
}

# Enumerate panes whose foreground process is claude. herdr step 1: process id.
function Get-ClaudePanes {
    psmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{session_name}|#{window_index}|#{pane_current_command}" 2>$null |
        Where-Object { $_ -match '\|claude$' } |
        ForEach-Object {
            $p = $_ -split '\|'
            [pscustomobject]@{ Target = $p[0]; Session = $p[1]; Window = $p[2] }
        }
}

# Remember the last non-transient state per pane so "unknown" (transcript
# viewer, model picker) holds the previous meaningful state instead of flapping.
$script:LastState = @{}

# All icons, as a character class, so we can strip a previously-applied icon
# from a session/window name and re-tag idempotently (never "● ● name").
$script:IconClass = '[' + (($script:AgentIcons.Values | ForEach-Object { [regex]::Escape($_) }) -join '') + ']'

# Strip a leading "<icon> " tag to recover the base name, so tagging is
# idempotent across polls (sessions named 0-5 have base names 0-5).
function Get-BaseName {
    param([string]$Name)
    ($Name -replace "^\s*$($script:IconClass)\s+", '').Trim()
}

# Separator between agents in the roll-up. Now that the publish channel is `@`
# user options (`set -g @agent_status`) instead of `set-environment`, SPACES ARE
# LEGAL in the value: set-option re-joins its value from all remaining args with
# spaces (psmux source connection.rs:2121), whereas set-environment kept only the
# first token (connection.rs:3842). So we use a readable " · " (middot with
# surrounding spaces) instead of the old bare-middot workaround.
$script:RollupSep = ' ' + [char]0x00B7 + ' '   # " · ", spaces now allowed

# --- State/manifest files (Task 1 + 2) --------------------------------------
# Directory for our sidecar files. Lives next to psmux's own registry.
$script:StatusDir     = Join-Path $HOME '.psmux\status'
# Manifest of window renames WE applied, so a crashed poller's tags are always
# restored on the next start (crash-safe restore). Maps a window target to its
# ORIGINAL (pre-tag) name.
$script:TagManifest   = Join-Path $script:StatusDir 'window-tags.json'
# JSON snapshot for other consumers (Task 2).
$script:StatusJson    = Join-Path $script:StatusDir 'agent-status.json'

function Ensure-StatusDir {
    if (-not (Test-Path $script:StatusDir)) {
        New-Item -ItemType Directory -Force -Path $script:StatusDir -ErrorAction SilentlyContinue | Out-Null
    }
}

# Atomic JSON write: temp file then Move-Item -Force (per reviewer's Task 2).
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

# Read the JSON snapshot (the shared channel for the hook tick, task 4). Returns
# the parsed object, or $null if missing/unreadable. Callers use `.updated`,
# `.rollup`, `.sessions`.
function Read-StatusSnapshot {
    if (-not (Test-Path $script:StatusJson)) { return $null }
    try { return (Get-Content $script:StatusJson -Raw -ErrorAction Stop | ConvertFrom-Json) }
    catch { return $null }
}

# Age of a snapshot's `updated` timestamp in seconds, or [double]::MaxValue if it
# can't be parsed (treated as "infinitely stale" so callers self-hide).
function Get-SnapshotAgeSeconds {
    param($Snapshot)
    if (-not $Snapshot -or -not $Snapshot.updated) { return [double]::MaxValue }
    try {
        $t = [datetimeoffset]::Parse($Snapshot.updated)
        return ([datetimeoffset]::Now - $t).TotalSeconds
    } catch { return [double]::MaxValue }
}

# Self-publish the roll-up to THIS server only (no -t; relies on the server-preset
# PSMUX_TARGET_SESSION for a hook child). This is the hook tick's publish path —
# every server self-publishes the same shared roll-up from the snapshot, so the
# mutex only needs to gate the expensive scan, not the publish (plan task 4,
# model 2). Single-quote the option name (splatting gotcha, see Publish-AgentStatusAll).
function Publish-AgentStatusSelf {
    param([string]$Rollup)
    psmux set -g '@agent_status' $Rollup 2>$null | Out-Null
}

# Self-hide: unset @agent_status on THIS server so its status-right #{?@agent_status,}
# guard drops the segment. Used when the snapshot is too stale to trust (the
# scanner has stopped) — the bar reverts to the themed default instead of
# freezing on old data. Also gives per-server correctness when a single server's
# updates stall (plan F1).
function Hide-AgentStatusSelf {
    psmux set -g -u '@agent_status' 2>$null | Out-Null
}

# EXPENSIVE PASS: capture + classify every claude pane, tag windows, build the
# roll-up, and write the JSON snapshot. Does NOT publish @agent_status — that is
# the caller's job (the daemon fans out via -t; the hook tick self-publishes from
# the snapshot). Returns the snapshot object it wrote so a caller can publish
# without re-reading the file.
#
# This is the split-out of the old monolithic Update-AgentStatus, so the
# hook-scheduled tick (psmux-agent-status-tick.ps1, task 4) can run JUST the scan
# under a mutex and let every server self-publish from the shared JSON.
function Invoke-AgentScan {
    $panes = @(Get-ClaudePanes)

    # Urgency ranking so a session with any blocked pane sorts as blocked
    # (attention-first, like herdr's priority sidebar sort). `none` (no agent) is
    # lowest so any real claude pane in a session outranks the no-agent baseline.
    $rank = @{ blocked = 3; working = 2; idle = 1; unknown = 0; none = -1 }

    # session base-name + most-urgent state, accumulated across its claude panes.
    $sessionState = [ordered]@{}
    $sessionBase  = @{}

    # per-pane state (for the JSON snapshot, Task 2).
    $paneStates = [ordered]@{}
    # window-tag manifest we (re)build this pass: target -> original name.
    $manifest = @{}

    # Pass 1: classify every claude pane, tag its WINDOW (not the session — see
    # below), and fold its state into the per-session most-urgent state. A session
    # can hold MULTIPLE claude panes; the roll-up collapses them to one entry per
    # session showing the most-urgent state.
    #
    # NOTE: we deliberately DO NOT rename sessions. Session renames mutate psmux's
    # ~\.psmux\<name>.{key,port,sid} registry filenames, which was the root of the
    # UTF-8/space targeting fragility. The roll-up (@agent_status) already carries
    # per-session state to the bar and switcher, so session tags are redundant.
    foreach ($pane in $panes) {
        $cap   = psmux capture-pane -t $pane.Target -p 2>$null
        $state = Get-AgentState -Lines @($cap)

        if ($state -eq 'unknown' -and $script:LastState.ContainsKey($pane.Target)) {
            $state = $script:LastState[$pane.Target]   # hold last real state
        } else {
            $script:LastState[$pane.Target] = $state
        }
        $paneStates[$pane.Target] = $state

        # (1) per-window rename, preserving the ORIGINAL name: tag as
        # "<icon> <original>" (not hardcoded "claude"). Record the original in the
        # manifest so restore returns the exact prior name even after a crash.
        $winTarget = "$($pane.Session):$($pane.Window)"
        $curName   = psmux display-message -t $winTarget -p "#{window_name}" 2>$null
        $orig      = Get-BaseName $curName   # strip any icon we previously applied
        if ($orig) { $manifest[$winTarget] = $orig }
        psmux rename-window -t $winTarget "$($script:AgentIcons[$state]) $orig" 2>$null | Out-Null

        # per-session most-urgent accumulation.
        if (-not $sessionBase.ContainsKey($pane.Session)) {
            $sessionBase[$pane.Session]  = Get-BaseName $pane.Session
            $sessionState[$pane.Session] = $state
        } elseif ($rank[$state] -gt $rank[$sessionState[$pane.Session]]) {
            $sessionState[$pane.Session] = $state
        }
    }

    # Persist the tag manifest so a crashed poller's window tags can be restored
    # on the next start (crash-safe restore).
    Write-JsonAtomic -Path $script:TagManifest -Object $manifest

    # Fold in EVERY session, including those with no claude pane, so the roll-up
    # shows the whole session list (user request). Agent-less sessions get state
    # `none` (bare name, no glyph). Preserve list-sessions ORDER for a stable bar;
    # sessions with claude panes keep the state accumulated above.
    $orderedState = [ordered]@{}
    foreach ($s in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $s) { continue }
        $b = Get-BaseName $s
        if ($sessionState.Contains($s)) {
            $orderedState[$s] = $sessionState[$s]     # has an agent — keep its state
        } else {
            $orderedState[$s] = 'none'                # no claude pane
            $sessionBase[$s]  = $b
        }
    }
    $sessionState = $orderedState

    # Build the roll-up from PER-SESSION state (one entry per session). Spaces are
    # legal (@ user option value). `none` has an empty icon, so those entries are
    # the bare name with no leading glyph/space ("psmux", not " psmux").
    $rollupParts = foreach ($sess in $sessionState.Keys) {
        $icon = $script:AgentIcons[$sessionState[$sess]]
        $base = $sessionBase[$sess]
        if ($icon) { "$icon $base" } else { "$base" }
    }
    $rollup = $rollupParts -join $script:RollupSep

    # Atomic JSON snapshot. This is BOTH the consumer feed (Task 3) AND the shared
    # channel the hook tick self-publishes from (task 4): `updated` lets a tick
    # decide whether to rescan (age gate) or self-hide (staleness). `sessions`
    # maps sessionName -> state so a tick can publish its OWN session's icon.
    $snap = [ordered]@{
        updated  = (Get-Date).ToString('o')
        rollup   = $rollup
        sessions = $sessionState
        panes    = $paneStates
    }
    Write-JsonAtomic -Path $script:StatusJson -Object $snap
    return $snap
}

# Publish the @agent_status USER OPTION into every session's server (options are
# server-scoped; each psmux session is its own server). psmux.conf's status-right
# embeds #{?@agent_status,...#{@agent_status}...,}. Used by the DAEMON path; the
# hook tick self-publishes to its own server instead (no -t).
#
# `set -g '@agent_status' "<value>"` re-joins the value with spaces
# (connection.rs:2121), so the readable roll-up survives intact — no middot-only
# workaround. We SKIP space-named sessions: a space breaks the -t positional arg;
# those are pathological session names we don't create.
#
# CRITICAL PowerShell gotcha: the option name MUST be SINGLE-QUOTED. A bare
# `@agent_status` token is PowerShell's SPLATTING operator — it expands the
# undefined variable `$agent_status` to nothing, so psmux receives
# `set -g "<value>"` (one positional) and silently ignores it with exit 0.
# '@agent_status' passes the literal name. (This exact bug produced a false
# "@ options don't work on this build" conclusion during development.)
function Publish-AgentStatusAll {
    param([string]$Rollup)
    foreach ($s in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $s) { continue }
        if ($s -match '\s') { continue }   # unsupported -t target; skip
        psmux set -g -t $s '@agent_status' $Rollup 2>$null | Out-Null
    }
}

# Unset @agent_status on ALL servers via -t (the fan-out counterpart of
# Publish-AgentStatusAll). Used when a fresh scan finds NO claude panes anywhere:
# every bar should drop its segment, not freeze on the last roll-up. Same
# single-quote gotcha as Publish-AgentStatusAll.
function Clear-AgentStatusAll {
    foreach ($s in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $s) { continue }
        if ($s -match '\s') { continue }   # unsupported -t target; skip
        psmux set -g -t $s -u '@agent_status' 2>$null | Out-Null
    }
}

# DAEMON path: scan + fan-out publish to all servers. Kept for the persistent
# poller (Start-AgentStatus) and manual use. The hook tick does NOT call this.
function Update-AgentStatus {
    $snap = Invoke-AgentScan
    Publish-AgentStatusAll -Rollup $snap.rollup
}

# Single-instance guard. Your sessions all live in one namespace and you switch
# with Ctrl+a s, so exactly ONE poller should run for the namespace — never one
# per session, and never a duplicate when a profile is re-sourced or another
# shell opens.
#
# We use a PID MARKER FILE rather than a named mutex. A mutex is technically the
# "right" primitive, but its ownership/abandonment semantics are hard to verify
# reliably from PowerShell and behave subtly across processes. A PID file is
# dead-simple to reason about and self-healing:
#   - "is a poller running?" = marker exists AND that PID is a live process.
#   - crash/kill/closed window leaves a STALE PID -> the process lookup fails ->
#     the next start treats the lock as free and takes over. No cleanup needed.
$script:PollerPidFile = Join-Path $env:TEMP 'psmux-agent-status.pid'

# Is a poller currently running (per the marker)? Returns the live PID or $null.
function Get-RunningPollerPid {
    if (-not (Test-Path $script:PollerPidFile)) { return $null }
    $recorded = (Get-Content $script:PollerPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $recorded) { return $null }
    $procId = 0
    if (-not [int]::TryParse($recorded.Trim(), [ref]$procId)) { return $null }
    # A recorded PID is only "running" if that process exists AND is pwsh (guards
    # against PID reuse by an unrelated process after a crash).
    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($p -and $p.ProcessName -match '^pwsh') { return $procId }
    return $null   # stale marker (crashed/closed) — treat as free
}

# Undo everything the poller changes, so tags never outlive the poller. This is
# CRASH-SAFE (Task 1): it's driven by the persisted tag manifest, so it works
# even if a previous poller died without cleaning up — the next start calls it
# BEFORE tagging anything. Two-pass:
#   1. From the manifest, rename each tagged window back to its recorded original.
#   2. Belt-and-suspenders: scan all windows and strip any leftover icon prefix
#      (covers windows tagged by a poller whose manifest was lost).
# Also clears the @agent_status option on every server; the status-right
# #{?@agent_status,...} guard then self-hides the segment, returning the bar to
# the themed default. We NO LONGER rename sessions, so no session names to restore.
function Restore-AgentStatus {
    # 1. manifest-driven exact-name restore.
    $manifest = Read-TagManifest
    foreach ($target in $manifest.Keys) {
        $orig = $manifest[$target]
        if ($orig) { psmux rename-window -t $target $orig 2>$null | Out-Null }
    }
    # 2. sweep any residual icon-tagged window names.
    foreach ($line in @(psmux list-panes -a -F "#{session_name}:#{window_index}|#{window_name}" 2>$null)) {
        $parts = $line -split '\|', 2
        if ($parts.Count -eq 2) {
            $wbase = Get-BaseName $parts[1]
            if ($wbase -ne $parts[1]) { psmux rename-window -t $parts[0] $wbase 2>$null | Out-Null }
        }
    }
    # clear @agent_status on every (space-free) session. `set -g -u '@agent_status'`
    # removes the user option (SetOptionUnset); the status-right #{?@agent_status,}
    # guard then self-hides the segment, returning the bar to the themed default.
    # Single-quote the option name (PowerShell splatting gotcha — see Update-AgentStatus).
    foreach ($sess in @(psmux list-sessions -F "#{session_name}" 2>$null)) {
        if (-not $sess -or ($sess -match '\s')) { continue }
        psmux set -g -t $sess -u '@agent_status' 2>$null | Out-Null
    }
    # manifest consumed — clear it so we don't re-restore stale entries.
    Remove-Item $script:TagManifest -ErrorAction SilentlyContinue
}

function Start-AgentStatus {
    [CmdletBinding()]
    param(
        [int]$IntervalSeconds = 5,
        [switch]$Once
    )
    # Clear any inherited psmux session env vars. A shell can carry a STALE
    # PSMUX_SESSION (e.g. "__warm__" left over from the pre-warm pool, or empty),
    # which redirects the psmux CLI to the wrong socket — making `set -g`
    # writes land on a warm server instead of the real sessions (observed: names
    # got tagged but @agent_status stayed empty). Clearing these makes the CLI use
    # the default/real socket so `-t <session>` targets the real servers.
    Remove-Item Env:\PSMUX_SESSION        -ErrorAction SilentlyContinue
    Remove-Item Env:\PSMUX_TARGET_SESSION -ErrorAction SilentlyContinue

    if ($Once) { Update-AgentStatus; return }

    $running = Get-RunningPollerPid
    if ($running -and $running -ne $PID) {
        Write-Host "psmux agent-status: a poller is already running (PID $running); not starting another."
        return
    }
    # Claim the lock by recording our PID (overwrites any stale marker).
    Set-Content -Path $script:PollerPidFile -Value $PID -Encoding ascii
    # CRASH-SAFE RESTORE (Task 1): a previous poller may have died without
    # cleaning up its window tags. Restore from the manifest BEFORE we tag
    # anything, so we start from a clean slate and never compound stale tags.
    try { Restore-AgentStatus } catch { }
    Write-Host "psmux agent-status poller running (PID $PID, every ${IntervalSeconds}s). Ctrl+C to stop."
    # RESILIENCE: earlier this loop exited on a SINGLE empty `list-sessions`, but
    # that read returns empty TRANSIENTLY (warm-socket hiccups, a psmux call
    # blipping), so one blip killed the poller and blanked the bar — the "poller
    # keeps dying / nothing updates" bug. Now we only quit after N CONSECUTIVE
    # empty reads (real shutdown), and a thrown Update-AgentStatus never kills the
    # process — it's caught and retried next tick.
    $emptyStreak = 0
    $maxEmpty    = 6   # ~30s of a truly-gone server before self-terminating
    try {
        while ($true) {
            $alive = psmux list-sessions -F "#{session_name}" 2>$null
            if (-not $alive) {
                $emptyStreak++
                if ($emptyStreak -ge $maxEmpty) { break }   # server really gone
            } else {
                $emptyStreak = 0
                try { Update-AgentStatus } catch { }        # never die on a blip
            }
            # Re-assert our PID marker each tick in case it was cleared/overwritten.
            if ((Get-Content $script:PollerPidFile -ErrorAction SilentlyContinue) -ne "$PID") {
                # Someone else claimed the lock — yield (they're the live poller).
                $other = Get-RunningPollerPid
                if ($other -and $other -ne $PID) { break }
                Set-Content -Path $script:PollerPidFile -Value $PID -Encoding ascii
            }
            Start-Sleep -Seconds $IntervalSeconds
        }
    } finally {
        # Restore names / clear AGENT_STATUS so nothing is left tagged on exit.
        # (Best-effort: if the server is already gone this is a no-op.)
        try { Restore-AgentStatus } catch {}
        # Only remove the marker if it's still ours (don't clobber a poller that
        # replaced us).
        if ((Get-RunningPollerPid) -eq $PID -or (Get-Content $script:PollerPidFile -ErrorAction SilentlyContinue) -eq "$PID") {
            Remove-Item $script:PollerPidFile -ErrorAction SilentlyContinue
        }
    }
}

# Detached, hidden, idempotent background launcher. Safe to call from a profile
# or a muxt launch — the PID guard ensures repeated calls don't stack pollers,
# and a crashed poller (stale PID) is transparently replaced on the next call.
function Start-AgentStatusBackground {
    [CmdletBinding()]
    param([int]$IntervalSeconds = 5)

    if (Get-RunningPollerPid) { return }       # a live poller already exists

    # CRITICAL: force UTF-8 in the detached shell. Without a profile, pwsh
    # defaults to a non-UTF-8 console encoding, which garbles the ●/◍/✓/· glyphs
    # AND the icon-tagged session names when reading `list-sessions`. That makes
    # `set -g -t "<garbled name>" @agent_status ...` silently miss the real
    # session, so @agent_status never lands (the whole feature appears dead).
    # NOTE: task 1 (@ user options) made the VALUE space-safe, but this bootstrap
    # is STILL REQUIRED — the poller reads session NAMES back to build each -t
    # target, so the mojibake risk moved but did not vanish. Do not remove.
    # Setting the console + $OutputEncoding to UTF-8 first fixes reading and writing.
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
