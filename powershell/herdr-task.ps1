# herdr session launcher — native Windows, a direct port of psmux-task.ps1
# (`mux-task` / `muxt`) onto herdr's CLI.
#
# Creates a herdr WORKSPACE with the 4 preferred tabs:
#   1 agent    -> runs `claude`
#   2 editor   -> runs `nvim`
#   3 lazygit  -> runs `lazygit`
#   4 shell    -> plain shell (no command)
#
# Mapping from the old psmux world:
#   psmux session  -> herdr workspace   (one per project/task)
#   psmux window   -> herdr tab
#   send-keys+WaitReady polling -> herdr `pane run <pane_id> <tool>` (no polling)
#   create-or-attach -> check `workspace list` for the label, focus if present
#
# Unlike psmux there is NO nesting guard and NO WaitReady loop: herdr runs a
# single persistent server (the "session"), workspaces live inside it, and
# `pane run` launches the tool directly in the tab's root pane. Attaching is
# just `herdr` (the TUI), which shows the workspace in the sidebar.
#
# Tab order matches the prefix+1..9 (prefix+shift+<digit> on the swapped
# layout) bindings in dotfiles/herdr/config.toml.
#
# Usage:
#   herdr-task                       # workspace "task" in the current directory
#   herdr-task my-api                # workspace "my-api" in the current directory
#   herdr-task my-api C:\src\my-api  # workspace "my-api" rooted at that path
#
# Re-running with an existing workspace label focuses it (create-or-attach).

function herdr-task {
    [CmdletBinding()]
    param(
        [string]$Name = 'task',
        [string]$Path = $PWD.Path
    )

    # Resolve to an absolute path; fail clearly if it doesn't exist.
    try {
        $dir = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    } catch {
        Write-Error "herdr-task: path not found: $Path"
        return
    }

    # Is the herdr server up? `herdr status server` reports running/stopped.
    # A workspace can only be created once the server exists; `herdr` (bare)
    # starts it, but that attaches the TUI and blocks. Instead we let the first
    # socket command spin it up, and fail clearly if that doesn't happen.
    $null = herdr status server 2>&1

    # --- create-or-attach ---------------------------------------------------
    # Look for an existing workspace with this label; focus it if found.
    $existing = $null
    $wsList = herdr workspace list 2>$null | ConvertFrom-Json
    if ($wsList -and $wsList.result -and $wsList.result.workspaces) {
        $existing = $wsList.result.workspaces | Where-Object { $_.label -eq $Name } | Select-Object -First 1
    }
    if ($existing) {
        herdr workspace focus $existing.workspace_id | Out-Null
        Write-Host "herdr-task: focused existing workspace '$Name' ($($existing.workspace_id))"
        Write-Host "Attach with:  herdr"
        return
    }

    # --- build the workspace ------------------------------------------------
    # Tab 1 (agent) is the workspace's root tab, created with the workspace.
    $created = herdr workspace create --label $Name --cwd $dir --no-focus 2>&1 | ConvertFrom-Json
    if (-not ($created -and $created.result -and $created.result.workspace)) {
        Write-Error "herdr-task: failed to create workspace. Is the herdr server running? Output: $created"
        return
    }
    $wsid      = $created.result.workspace.workspace_id
    $agentPane = $created.result.root_pane.pane_id   # tab 1 root pane

    # Rename the auto-created first tab (label defaults to "1") to "agent".
    herdr tab rename $created.result.tab.tab_id agent | Out-Null

    # Tabs 2-4. Each returns its own root_pane we run the tool in.
    $editorPane  = (herdr tab create --workspace $wsid --label editor  --cwd $dir --no-focus 2>&1 | ConvertFrom-Json).result.root_pane.pane_id
    $lazygitPane = (herdr tab create --workspace $wsid --label lazygit --cwd $dir --no-focus 2>&1 | ConvertFrom-Json).result.root_pane.pane_id
    # Tab 4 (shell) intentionally runs nothing — a plain prompt.
    $null        = (herdr tab create --workspace $wsid --label shell   --cwd $dir --no-focus 2>&1 | ConvertFrom-Json)

    # Launch the tools directly in each pane (replaces send-keys + WaitReady).
    herdr pane run $agentPane   claude  | Out-Null
    herdr pane run $editorPane  nvim    | Out-Null
    herdr pane run $lazygitPane lazygit | Out-Null

    # Focus the workspace so it's front-and-center on attach.
    herdr workspace focus $wsid | Out-Null

    Write-Host "herdr-task: created workspace '$Name' ($wsid) at $dir"
    Write-Host "Attach with:  herdr"
}

Set-Alias -Name herdt -Value herdr-task -Scope Global
