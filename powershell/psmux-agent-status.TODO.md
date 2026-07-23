# psmux-agent-status — TODO / instructions

Installed psmux: 3.3.7 (05cc5d4, 2026-07-20). Facts below verified against the
source clone (`~/dev/psmux` @ f83637b) + the psmux-plugins repo, not guessed.

## Open items

- **Verify live (user, real use):** (1) all-sessions-in-TUI-for->15s → bars
  self-hide, not freeze; (2) sustained multi-session use over minutes.
  (Purple-flash-on-switch already confirmed gone.)
- **Orphan-sweep boundary (accepted, watch for pain):** the residual-icon sweep
  runs ONCE per psmux era (first scan; marker `$env:TEMP\psmux-agent-status.swept`).
  F3 handles the normal mid-run claude-exit case, so this only matters for
  orphans created mid-session by an unexpected path — those wait for a restart
  or a manual `Restore-AgentStatus`. If mid-session orphans turn out common,
  switch to sweeping every scan (one extra `list-panes` spawn per scan).

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
    why the tick fans out via `-t` rather than relying on each server's own hook.
11. `$script:`-scoped state does NOT survive across ticks — each hook tick is a
    fresh pwsh process. Anything that must persist tick-to-tick (the tag manifest
    for F3, the orphan-sweep marker) MUST be on disk. (The classifier's
    "hold last state on unknown" via `$script:LastState` is therefore per-tick
    only under hooks; acceptable, but noted.)

## Rejected (do not retry)

- **`#()` in status-right** — sync per-frame expansion (fact 3).
- **Session renaming** — registry mutation; choose-tree hardcoded to `.port` stem.
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
