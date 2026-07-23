# psmux-agent-status — TODO / instructions

Updated 2026-07-23 after a source review of psmux (clone at `~/dev/psmux`,
commit f83637b) and the psmux-plugins repo (clone at `~/dev/psmux-plugins`).
Installed binary: 3.3.7 (05cc5d4, 2026-07-20). Facts below were verified
against the source, not guessed — treat them as ground truth.

## Decisions

- **DROP session renaming entirely.** The choose-tree switcher displays the
  session name straight from the `.port` file *stem* (`src/session.rs:1501-1543`,
  no `-F`/format support), so icons there require real renames — and renames
  mutate the `~/.psmux` registry filenames, which is the root of the unicode
  targeting fragility. Not worth it. Session-level state moves to the status
  bar instead (task 1). Remove all `rename-session` logic, including from
  `Restore-AgentStatus`.
- **Keep the env-var-style push architecture** (publish to every server each
  tick), but migrate the channel from `set-environment` to `@` user options
  (task 1). Do NOT migrate to `#()` shell evaluation in status-right (see
  Rejected approaches).
- **Keep window renaming** for per-window state, but make it name-preserving
  and crash-safe (task 2). There are no window-scoped `@` options in psmux
  (`set -w` parses but `@` values land in one global-per-server map), so
  rename-window remains the only per-window channel.

## Verified psmux facts

1. `set-option` re-joins its value from all remaining args with spaces
   (`src/server/connection.rs:2121`), while `set-environment` keeps only the
   first token and silently drops the rest (`connection.rs:3842`). So
   **`@` user options may contain spaces; env var values may not.** After the
   migration in task 1 the no-space middot workaround is unnecessary.
2. Format lookup for an unknown `#{name}` checks `user_options` (the `@` map)
   BEFORE the session environment table (`src/format.rs:967-980`). `#{@foo}`
   and `#{?@foo,...,...}` both resolve from options set via `set -g @foo ...`.
3. **Never put `#(command)` in status-right** on this build: the server-push
   render path expands `#()` synchronously on the server loop, per pushed
   frame, with no TTL cache (missing AsyncFormatGuard at
   `src/server/mod.rs:~5562`). It would stall all panes during output.
4. The stale-routing bug we hit (writes landing on a warm server) is psmux
   issue #485; the fix (commit 061ac56, `$TMUX` overrides stale
   `PSMUX_TARGET_SESSION`) is upstream but NOT in the installed 05cc5d4 build.
   **Keep clearing `PSMUX_SESSION` / `PSMUX_TARGET_SESSION` at poller start**
   until the installed build includes it. Re-check on every psmux upgrade.
5. psmux **strips backslashes** from command strings stored for later
   execution (`bind-key`, `set-hook`). Always convert script paths to
   forward slashes first. Never inline PowerShell in those strings — point
   at a script file.
6. `set-hook -ga` APPENDS; repeated setup accumulates duplicate hooks. Unset
   with `set-hook -gu <event>` before re-registering, and verify with
   `show-hooks`.
7. `run-shell` children are spawned async (the server drains results
   non-blocking) and receive `PSMUX_TARGET_SESSION` preset to the server that
   ran the hook — a hook script targets its own server with no `-t`.
8. `psmux ls` returns exit code 0 with EMPTY output when no server exists —
   confirmed independently by psmux-continuum (`auto_save.ps1`). The
   `$emptyStreak` liveness logic is correct; keep it.

## Tasks (priority order)

### 1. Migrate the publish channel: `set-environment` → `@` user options
- In `Update-AgentStatus`, replace the `set-environment` fan-out with:
  `psmux set -g -t <session> @agent_status "<rollup>"` — same loop over
  `list-sessions`, same explicit `-t` per session.
- Spaces are now legal in the value: replace the middot-only separator with
  normal readable spacing (e.g. `● dotfiles · ✓ test`). Still guard against
  session names that themselves contain `|` or quotes.
- Also publish each session's OWN most-urgent icon to that session's server:
  `psmux set -g -t <session> @agent_state "<icon>"` (this replaces what
  session renaming used to convey).
- Update `~/dotfiles/psmux.conf`:
  - status-right: change `#{?AGENT_STATUS,...#{AGENT_STATUS}...,}` to
    `#{?@agent_status,...#{@agent_status}...,}` (keep the self-hiding guard).
  - status-left: show the local session's state inside the themed segment,
    e.g. prepend `#{?@agent_state,#{@agent_state} ,}` before `#S`.
- Cleanup path: unset with `psmux set -g -t <session> -u @agent_status` (and
  `@agent_state`). `SetOptionUnset` removes `@` options
  (`src/server/mod.rs`, drain/CtrlReq handlers).
- Delete all `rename-session` calls and the session-name icon-stripping in
  `Restore-AgentStatus` (sessions are never touched anymore).

### 2. Make window tagging name-preserving and crash-safe
- Tag as `<icon> <original-window-name>` instead of hardcoding
  `<icon> claude`.
- Persist a manifest (e.g. `~/.psmux/status/agent-status-manifest.json`) of
  every window renamed and its original name. On poller start (including
  takeover after a stale PID) restore from any leftover manifest FIRST, then
  begin tagging. On clean exit, restore and delete the manifest. This closes
  the "hard kill leaves names tagged" hole.

### 3. Publish a JSON snapshot each tick
`~/.psmux/status/agent-status.json`: per-session states, per-pane states,
roll-up string, ISO-8601 `updated` timestamp. Write atomically: temp file in
the same directory, then `Move-Item -Force`. This is for other consumers;
the status bar keeps using `@agent_status`.

### 4. OPTIONAL redesign: hook-scheduled instead of a daemon
Pattern from psmux-cpu (`~/dev/psmux-plugins/psmux-cpu/plugin.conf`): the
server itself fires `status-interval` hooks every `status-interval` seconds:
```
set-hook -ga status-interval 'run-shell "pwsh -NoProfile -File C:/Users/MZawisa/dotfiles/powershell/psmux-agent-status-tick.ps1"'
set-hook -ga client-attached 'run-shell "..."'   # immediate refresh on attach
```
Each server fires its own hook; the tick script would: try a named mutex —
the winner does the expensive capture/classify pass and writes the JSON
snapshot; every instance (winner or not) reads the snapshot and publishes
`@agent_status`/`@agent_state` to its OWN server (no `-t` needed — see fact
7). This eliminates the persistent daemon, the PID file, and the
resurrection problem: if a tick dies, the next interval fires anyway.
Trade-off to measure first: one pwsh spawn per server per interval vs one
persistent process. Mind facts 5 and 6 (forward slashes, -gu before -ga).

### 5. OPTIONAL: singleton primitive
If the PID-file guard ever misbehaves, psmux-continuum's named-mutex pattern
(`~/dev/psmux-plugins/psmux-continuum/psmux-continuum.ps1`, auto_save
section) handles the abandonment case the old TODO worried about in ~8 lines:
`WaitOne(0)` in try/catch, `AbandonedMutexException` → reclaim. Either
primitive is fine; don't use `Start-Job` for the background launch (job dies
with its parent) — keep `Start-Process -WindowStyle Hidden`.

## Deferred: control-mode socket (updated with protocol findings)

**Idea:** replace per-poll `psmux.exe` CLI spawns (~200ms each — profiled as
the poller's dominant cost) with persistent connections.

**Protocol (verified in source):** plain TCP on loopback. Port is in
`~/.psmux/<base>.port`, auth key in `<base>.key`. Handshake: send
`AUTH <key>` + newline, then command lines. Client implementation to mimic:
`~/dev/psmux/src/session.rs:1191-1302` (`send_control`,
`send_control_with_response`). One connection per server (one server per
session). Use UTF-8 on the stream.

**Still to verify empirically:** whether one connection accepts multiple
sequential commands or must be reopened per command, and whether
`capture-pane -p` output returns over the same stream. If persistent
connections work, keep one `System.Net.Sockets.TcpClient` per server and
measure a full poll pass before/after. Worth it only for many sessions or
sub-second blocked-latency; a handful of agents at 5s does not need it.

## Rejected approaches (do not retry)

- **`#()` in status-right** — sync per-frame expansion on this build (fact 3).
- **Session renaming** — registry mutation + choose-tree is hardcoded anyway
  (see Decisions).
- **`window_activity_flag` gating** for cheaper polling — tested and
  rejected earlier: it flags "background window changed since last viewed"
  (a notification primitive), NOT "pane is emitting output". It stayed 0
  while claude worked, even with monitor-activity on. The real fix for
  per-pane capture cost is the control socket.
- **psmux plugin packaging** — considered and declined for now: every
  pattern above works from plain config + scripts; a plugin adds only
  packaging/distribution. (If ever revisited: plugin entry scripts must exit
  fast — the server waits up to 5s for them at startup — and a `.ps1` whose
  set/bind lines can be statically extracted is applied WITHOUT being
  executed, `src/config.rs:1225-1233`. Use plugin.conf + a `run` launcher
  line, like ppm.)

## On every psmux upgrade past 05cc5d4, re-check

1. Whether issue #485 (061ac56) is included → the env-clearing at poller
   start becomes unnecessary (keep it anyway; it's harmless).
2. Whether the server-push `#()` path gained an AsyncFormatGuard
   (`src/server/mod.rs` around the `has_frame_receivers` push block) → `#()`
   in status formats becomes viable again.
