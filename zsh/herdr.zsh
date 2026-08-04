# herdr shell integration — the zsh side of powershell/herdr-task.ps1.
#
# herdr-task creates a herdr WORKSPACE with the 4 preferred tabs:
#   1 claude   -> runs `claude`
#   2 editor   -> runs `nvim`
#   3 lazygit  -> runs `lazygit`
#   4 shell    -> plain shell (no command)
#
# This mirrors tmuxinator/task.yaml (`mux task`) and the psmux/herdr PowerShell
# launchers, so the same 4-window muscle memory works on every machine:
#   tmuxinator session -> herdr workspace   (one per project/task)
#   tmuxinator window  -> herdr tab
#
# Tab order matches the prefix+1..9 bindings in dotfiles/herdr/config.toml.
#
# Usage:
#   herdr-task                       # workspace "task" in the current directory
#   herdr-task my-api                # workspace "my-api" in the current directory
#   herdr-task my-api ~/src/my-api   # workspace "my-api" rooted at that path
#
# Re-running with an existing workspace label focuses it (create-or-attach).

herdr-task() {
    emulate -L zsh
    setopt local_options no_unset

    local name="${1:-task}"
    # NOT `path` — that is zsh's array alias for PATH; assigning a string to it
    # replaces PATH with a single directory and every command lookup then fails.
    local target="${2:-$PWD}"

    # command -v rather than $commands[...] — the latter only reflects commands
    # already in the hash table, so it reports false for anything not yet run.
    if [[ ! -x "$(command -v herdr)" ]]; then
        print -u2 "herdr-task: herdr not found in PATH"
        return 1
    fi
    if [[ ! -x "$(command -v jq)" ]]; then
        print -u2 "herdr-task: jq is required to parse herdr's JSON output"
        return 1
    fi

    # Resolve to an absolute path; fail clearly if it doesn't exist.
    local dir
    if ! dir=$(cd -- "$target" 2>/dev/null && pwd -P); then
        print -u2 "herdr-task: path not found: $target"
        return 1
    fi

    # A workspace can only be created once the server exists. Bare `herdr`
    # would start it, but that attaches the TUI and blocks, so probe instead
    # and let the first socket command spin it up.
    herdr status server >/dev/null 2>&1

    # --- create-or-attach ---------------------------------------------------
    local existing
    existing=$(herdr workspace list 2>/dev/null \
        | jq -r --arg n "$name" '.result.workspaces[]? | select(.label == $n) | .workspace_id' \
        | head -1)

    if [[ -n $existing ]]; then
        herdr workspace focus "$existing" >/dev/null 2>&1
        print "herdr-task: focused existing workspace '$name' ($existing)"
        print "Attach with:  herdr"
        return 0
    fi

    # --- build the workspace ------------------------------------------------
    # Tab 1 (claude) is the workspace's root tab, created with the workspace.
    local created
    created=$(herdr workspace create --label "$name" --cwd "$dir" --no-focus 2>&1)

    local wsid claude_pane claude_tab
    wsid=$(print -r -- "$created" | jq -r '.result.workspace.workspace_id // empty' 2>/dev/null)
    claude_pane=$(print -r -- "$created" | jq -r '.result.root_pane.pane_id // empty' 2>/dev/null)
    claude_tab=$(print -r -- "$created" | jq -r '.result.tab.tab_id // empty' 2>/dev/null)

    if [[ -z $wsid || -z $claude_pane ]]; then
        print -u2 "herdr-task: failed to create workspace. Is the herdr server running?"
        print -u2 "herdr-task: output: $created"
        return 1
    fi

    # Rename the auto-created first tab (label defaults to "1") to "claude".
    [[ -n $claude_tab ]] && herdr tab rename "$claude_tab" claude >/dev/null 2>&1

    # Tabs 2-4. Each returns its own root_pane we run the tool in.
    local editor_pane lazygit_pane
    editor_pane=$(herdr tab create --workspace "$wsid" --label editor --cwd "$dir" --no-focus 2>/dev/null \
        | jq -r '.result.root_pane.pane_id // empty')
    lazygit_pane=$(herdr tab create --workspace "$wsid" --label lazygit --cwd "$dir" --no-focus 2>/dev/null \
        | jq -r '.result.root_pane.pane_id // empty')
    # Tab 4 (shell) intentionally runs nothing — a plain prompt.
    herdr tab create --workspace "$wsid" --label shell --cwd "$dir" --no-focus >/dev/null 2>&1

    # Launch the tools directly in each pane. `pane run` prints nothing on
    # success; a missing tool surfaces in the pane itself, not here.
    herdr pane run "$claude_pane" claude >/dev/null 2>&1
    [[ -n $editor_pane ]] && herdr pane run "$editor_pane" nvim >/dev/null 2>&1
    [[ -n $lazygit_pane ]] && herdr pane run "$lazygit_pane" lazygit >/dev/null 2>&1

    # Focus the workspace so it's front-and-center on attach.
    herdr workspace focus "$wsid" >/dev/null 2>&1

    print "herdr-task: created workspace '$name' ($wsid) at $dir"
    print "Attach with:  herdr"
}

alias herdt=herdr-task

# Complete the second arg as a directory, matching the _mux completion style.
_herdr_task() {
    if (( CURRENT == 2 )); then
        _message 'workspace name'
    elif (( CURRENT == 3 )); then
        _directories
    fi
}
compdef _herdr_task herdr-task herdt

# herdr's own completions, when the binary can generate them.
if [ -x "$(command -v herdr)" ]; then
    source <(herdr completion zsh) 2>/dev/null
fi
