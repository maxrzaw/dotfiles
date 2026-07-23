# psmux-agent-status — TODO / instructions

Installed psmux: 3.3.7 (05cc5d4, 2026-07-20). Facts below verified against the
source clone (`~/dev/psmux` @ f83637b) + the psmux-plugins repo, not guessed.

## Open items

- **F2 — empty `$orig` renames a window to a bare icon.** If
  `display-message -p "#{window_name}"` returns nothing, `$orig` is `''`: the
  manifest gets no entry but `rename-window` still runs, naming the window
  `"● "`, which the restore sweep can't strip (its regex needs
  `<icon><space><name>`). Fix: skip the rename when `$orig` is empty/whitespace.
- **F3 — tags outlive claude mid-run.** The manifest is rebuilt each tick from
  CURRENT claude panes, and restore runs only at start/exit. A window whose
  claude process exits keeps its icon until a restore. Fix: diff the previous
  tick's manifest against the current one and rename departed targets back
  immediately (then drop them).
- **F4 — minor perf (optional).** Add `#{window_name}` to the `Get-ClaudePanes`
  format string to drop the per-pane `display-message` spawn, and skip
  `rename-window` when the name is already `"<icon> <orig>"`.
- **Verify live (user, real use):** (1) purple flash gone on session switch;
  (2) all-sessions-in-TUI-for->15s → bars self-hide, not freeze; (3) sustained
  multi-session use over minutes.

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
   NOT in 05cc5d4. Clear `PSMUX_SESSION`/`PSMUX_TARGET_SESSION` in USER-SHELL
   entry paths (`Start-AgentStatus`, manual). Do NOT clear them in the hook
   child — the server presets `PSMUX_TARGET_SESSION` to itself and the no-`-t`
   self-publish relies on it (use the `__warm__$` guard there instead).
5. psmux **strips backslashes** from stored command strings (`bind-key`,
   `set-hook`). Use forward slashes; point at a script file, never inline PS.
6. `set-hook -ga` APPENDS → `-gu <event>` before `-ga` to avoid duplicates.
7. `run-shell` children are async and receive `PSMUX_TARGET_SESSION` preset to
   the server that ran the hook (so a hook script targets its own server, no `-t`).
8. `psmux ls` returns exit 0 with EMPTY output when no server exists. The
   `$emptyStreak` liveness logic is correct.
9. **`@` options MUST be single-quoted from PowerShell** (`'@agent_status'`). A
   bare `@name` token is PowerShell SPLATTING → expands undefined `$name` to
   nothing → psmux gets one positional and silently ignores it (exit 0). This
   produced a false "@ options don't work" conclusion during dev. Verified
   working once quoted. (Memory: [[psmux-atsign-option-splatting]].)
10. `status-interval` does NOT fire uniformly across servers (reproducible: 2 of
    4 sessions ticked, correlated with attach/full-screen-TUI state). This is
    why the tick fans out via `-t` rather than relying on each server's own hook
    (see "hybrid" below).

## Done — changelog (context only, not TODO)

- **Publish channel:** `set-environment`/`AGENT_STATUS` → `@agent_status` user
  option (single-quoted, fact 9); readable `" · "` separator; conf guard
  `#{?@agent_status,...}`. UTF-8 bootstrap + user-shell env-clearing retained.
- **No session renaming** anywhere (registry-mutation fragility; choose-tree is
  hardcoded to the `.port` stem anyway). Roll-up in status-right supersedes the
  picker-visibility motive.
- **Window tagging** is name-preserving (`<icon> <original>`) and crash-safe via
  manifest `~/.psmux/status/window-tags.json` (restore at start/exit + sweep).
- **JSON snapshot** `~/.psmux/status/agent-status.json` written atomically each
  scan (consumer feed + the tick's shared channel).
- **Roll-up shows ALL sessions** (not just those with a claude pane);
  agent-less ones use state `none` (empty icon → bare name).
- **Hook-scheduled, no daemon (hybrid):** `psmux.conf` registers a single
  `status-interval` hook → `psmux-agent-status-tick.ps1`. A named mutex elects
  one scanner per interval (age-gated so staggered per-server ticks don't
  re-scan); the scanner fans `@agent_status` out to EVERY server via `-t` (fact
  10 forces this over pure self-publish); each tick also self-publishes to its
  own server; snapshot older than ~3 intervals → self-hide. Daemon functions
  stay in `psmux-agent-status.ps1` for manual/fallback use; profile no longer
  references the feature. `client-attached` hook dropped (purple-flash on every
  switch; redundant under `-t` fan-out). Singleton: the tick uses the
  continuum-style `WaitOne(0)` + `AbandonedMutexException` reclaim; the old
  PID-file guard now only governs the legacy daemon.

## Rejected (do not retry)

- **`#()` in status-right** — sync per-frame expansion (fact 3).
- **Session renaming** — registry mutation; choose-tree hardcoded.
- **status-left `@agent_state`** — only shows the session you're already on.
- **`window_activity_flag` gating** — flags "changed since last viewed", not
  "emitting output"; stayed 0 while claude worked.
- **Pure self-publish (no `-t`)** — fact 10: bars on non-ticking servers stay
  blank.
- **psmux plugin packaging** — plain config + scripts suffice. (If revisited:
  entry scripts must exit fast, server waits ≤5s at startup; a `.ps1` whose
  set/bind lines are statically extractable is applied WITHOUT executing,
  `config.rs:1225-1233` — use plugin.conf + a `run` launcher line, like ppm.)

## On every psmux upgrade past 05cc5d4, re-check

1. Issue #485 (061ac56) included → user-shell env-clearing becomes unnecessary
   (harmless to keep).
2. Server-push `#()` path gained an AsyncFormatGuard (`src/server/mod.rs` near
   the `has_frame_receivers` push block) → `#()` in status formats viable again.
