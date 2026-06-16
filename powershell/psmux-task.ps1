# psmux session launcher — native Windows replacement for the old WSL
# `tmuxinator` (`mux task` / `mux windev`) workflow.
#
# Creates a psmux session with the 4 preferred windows:
#   1 claude   -> launches `claude`
#   2 editor   -> launches `nvim`
#   3 lazygit  -> launches `lazygit`
#   4 shell    -> plain pwsh prompt
#
# Each window is a normal pwsh shell (so your profile/aliases/prompt load), and
# the tool is started by typing it at the prompt via `send-keys`. Quitting the
# tool therefore drops you back to a live pwsh prompt in the project directory.
# (The `-- pwsh -Command "..."` form does NOT work in psmux — it launches pwsh
# but drops the trailing args — so send-keys is the supported approach.)
#
# Works both from a plain terminal and from inside an existing psmux session:
#   - psmux refuses `new-session` while PSMUX_SESSION is set (nesting guard), so
#     we clear it for the build commands. That creates a *sibling* session on the
#     same server (not a nested server).
#   - To land in the new session we then `attach` (from outside psmux) or
#     `switch-client` (from inside an existing client).
#
# Window names line up with the `Ctrl+a j/k/l/;` bindings in
# ~/dotfiles/psmux.conf (windows 1-4).
#
# Usage:
#   mux-task                      # session "task" in the current directory
#   mux-task my-api               # session "my-api" in the current directory
#   mux-task my-api C:\src\my-api # session "my-api" rooted at that path
#
# Re-running with an existing session name switches to it (create-or-attach).

function mux-task {
    [CmdletBinding()]
    param(
        [string]$Name = 'task',
        [string]$Path = $PWD.Path
    )

    # Resolve to an absolute path; fail clearly if it doesn't exist.
    try {
        $dir = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    } catch {
        Write-Error "mux-task: path not found: $Path"
        return
    }

    # Were we launched from inside an existing psmux client? This decides whether
    # we attach (outside) or switch-client (inside) at the end. Capture it BEFORE
    # we clear the env var for the build commands.
    $inside = [bool]$env:PSMUX_SESSION
    $savedSession = $env:PSMUX_SESSION

    function private:GoTo([string]$session) {
        if ($inside) {
            psmux switch-client -t $session
        } else {
            # Use the POSITIONAL form, not `attach -t`. psmux bug #393: the `-t`
            # value is stripped before the attach handler reads it, so `attach -t
            # NAME` falls through to the most-recent session. `attach NAME` works.
            psmux attach $session
        }
    }

    try {
        # Clear PSMUX_SESSION so new-session/new-window don't trip the nesting
        # guard. The commands still target the running server via its socket, so
        # this creates a sibling session, not a nested psmux server.
        $env:PSMUX_SESSION = $null
        Remove-Item Env:\PSMUX_SESSION -ErrorAction SilentlyContinue

        # Create-or-attach: if the session already exists, just go to it.
        # has-session exits 0 when the session exists, non-zero otherwise.
        psmux has-session -t $Name 2>$null
        if ($LASTEXITCODE -eq 0) {
            private:GoTo $Name
            return
        }

        # Window 1 (claude) is created with the detached session. Each window
        # starts in $dir (-c) as a plain pwsh shell; the tool is sent below.
        psmux new-session -d -s $Name -c $dir -n claude  -- pwsh
        psmux new-window      -t $Name -c $dir -n editor  -- pwsh
        psmux new-window      -t $Name -c $dir -n lazygit -- pwsh
        psmux new-window      -t $Name -c $dir -n shell   -- pwsh

        # Map of window -> command to run in it. The shell window stays empty.
        $tools = [ordered]@{
            claude  = 'claude'
            editor  = 'nvim'
            lazygit = 'lazygit'
        }

        # Wait for each pane's pwsh to finish loading the profile before typing,
        # so the keystrokes land at a ready prompt. While the profile runs
        # (oh-my-posh, etc.) pane_current_command reports the busy process; once
        # idle it settles to "pwsh". Poll for that, with a timeout fallback.
        function private:WaitReady([string]$target) {
            for ($i = 0; $i -lt 40; $i++) {   # up to ~8s
                $cmd = psmux display-message -t $target -p '#{pane_current_command}' 2>$null
                if ($cmd -match '^pwsh') { return }
                Start-Sleep -Milliseconds 200
            }
        }

        foreach ($win in $tools.Keys) {
            $target = "${Name}:${win}"
            private:WaitReady $target
            psmux send-keys -t $target $tools[$win] Enter
        }

        # Focus the claude window and go to the session.
        psmux select-window -t "${Name}:claude"
        private:GoTo $Name
    }
    finally {
        # Restore the original env var for the caller's shell.
        if ($null -ne $savedSession) { $env:PSMUX_SESSION = $savedSession }
    }
}

Set-Alias -Name muxt -Value mux-task -Scope Global
