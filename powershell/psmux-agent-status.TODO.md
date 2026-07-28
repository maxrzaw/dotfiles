# psmux-agent-status — TODO / instructions

Installed psmux: 3.3.7 (05cc5d4, 2026-07-20). Facts below verified against the
source clone (`~/dev/psmux` @ f83637b) + the psmux-plugins repo, not guessed.

## Scheduler: background daemon (NOT hooks)

The feature is driven by the persistent poller `Start-AgentStatusBackground`,
started from the PowerShell profile. It polls every 5s on its own timer and
fans the roll-up to every server via `-t`.

Hook-scheduling (a `status-interval` hook running the tick per server) was tried
and REVERTED: `status-interval` only fires when psmux redraws the status bar,
and redraws stop while a pane is in a full-screen TUI — i.e. whenever claude is
open, which is exactly when the bar needs to update. With every session sitting
in the claude TUI the snapshot froze for minutes. A plain timer sidesteps this.
`psmux-agent-status-tick.ps1` still exists and is bound to `prefix a` for a
manual refresh, but is no longer the primary path.

## Open items

- **Verify live (user, real use):** sustained multi-session use over minutes —
  daemon stays alive and the bar tracks state while inside the claude TUI.
- **Orphan-sweep boundary (accepted, watch for pain):** the residual-icon sweep
  runs ONCE per run (marker `$env:TEMP\psmux-agent-status.swept`). The per-poll
  revert handles the normal mid-run claude-exit case, so this only matters for
  orphans created by an unexpected path — those wait for a restart or a manual
  `Restore-AgentStatus`. If common, switch to sweeping every poll (one extra
  `list-panes` spawn).
- **Daemon startup reliability (historical, watch):** the detached poller has in
  the past failed to survive a launch. The PID-guard + profile launch is the
  current bet. If the bar is ever blank, check the snapshot age in
  `~/.psmux/status/agent-status.json` — if stale, the daemon died; re-run
  `Start-AgentStatusBackground`.

### Deferred: control-mode socket
Replace per-poll `psmux.exe` CLI spawns (~200ms each, the dominant cost) with
persistent TCP connections. Protocol (source-verified): loopback TCP, port in
`~/.psmux/<base>.port`, key in `<base>.key`; send `AUTH <key>\n` then command
lines, UTF-8. Client to mimic: `src/session.rs:1191-1302` (`send_control`).
Unverified: whether one connection takes multiple sequential commands, and
whether `capture-pane -p` output returns on the stream. Worth it only for many
sessions or sub-second latency; a handful at 5s does not need it.

## Verified psmux facts (durable reference)

1. `set-option` re-joins its value from all remaining args with spaces
   (`connection.rs:2121`); `set-environment` keeps only the first token
   (`connection.rs:3842`). **`@` options may contain spaces; env vars may not.**
2. Format lookup for `#{name}` checks `user_options` (the `@` map) BEFORE the
   session env table (`format.rs:967-980`). `#{@foo}` / `#{?@foo,...,...}`
   resolve from `set -g @foo ...`.
3. **Never put `#(command)` in status-right** on this build: the server-push
   render path expands `#()` synchronously per frame, no TTL cache
   (`src/server/mod.rs:~5562`). Would stall panes.
4. Stale warm-server routing = psmux issue #485; fix (061ac56) is upstream but
   NOT in 05cc5d4. Clear `PSMUX_SESSION`/`PSMUX_TARGET_SESSION` at daemon start
   so `-t` targets the real servers, not a warm standby.
5. psmux **strips backslashes** from stored command strings (`bind-key`,
   `set-hook`). Use forward slashes; point at a script file, never inline PS.
6. `set-hook -ga` APPENDS → `-gu <event>` before `-ga` to avoid duplicates.
7. `psmux ls` returns exit 0 with EMPTY output when no server exists. The
   `$emptyStreak` liveness logic is correct.
8. **`@` options MUST be single-quoted from PowerShell** (`'@agent_status'`). A
   bare `@name` token is PowerShell SPLATTING → expands undefined `$name` to
   nothing → psmux gets one positional and silently ignores it (exit 0). This
   produced a false "@ options don't work" conclusion during dev. Verified
   working once quoted. (Memory: [[psmux-atsign-option-splatting]].)
9. **`status-interval` only fires while psmux is redrawing the status bar**, and
   redraws STOP when the active pane is a full-screen TUI (`alternate_on=1`, e.g.
   claude). So a `status-interval` hook goes silent exactly when claude is open.
   This is why hook-scheduling was abandoned for the daemon.
10. **A claude pane's `pane_current_command` can be `claude.exe.old`**, not
    `claude`, after a Claude Code self-update: Windows can't delete the running
    exe, so the updater renames it and the process keeps the `.old` image name
    until the pane restarts. Match `^claude(\.exe)?(\.old)?$`, not `-eq 'claude'`.

## Rejected (do not retry)

- **`status-interval` hook scheduling** — the hook stops firing while a pane is
  in a full-screen TUI (fact 9), so the bar freezes whenever claude is open. Use
  the daemon's own timer.
- **`#()` in status-right** — sync per-frame expansion (fact 3).
- **Session renaming** — registry mutation; choose-tree hardcoded to `.port` stem.
- **status-left `@agent_state`** — only shows the session you're already on.
- **`window_activity_flag` gating** — flags "changed since last viewed", not
  "emitting output"; stayed 0 while claude worked.
- **psmux plugin packaging** — plain config + scripts suffice. (If revisited:
  entry scripts must exit fast, server waits ≤5s at startup; a `.ps1` whose
  set/bind lines are statically extractable is applied WITHOUT executing,
  `config.rs:1225-1233` — use plugin.conf + a `run` launcher line, like ppm.)

## On every psmux upgrade past 05cc5d4, re-check

1. Issue #485 (061ac56) included → user-shell env-clearing becomes unnecessary
   (harmless to keep).
2. Server-push `#()` path gained an AsyncFormatGuard (`src/server/mod.rs` near
   the `has_frame_receivers` push block) → `#()` in status formats viable again.
