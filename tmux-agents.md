# Running Multiple AI Agents with tmux + tmuxinator

## Overview

The goal is to run several independent AI agent sessions simultaneously — one per project or task — without them interfering with each other. Each session is a self-contained workspace with dedicated windows for the agent, editor, git, and a shell. tmuxinator templates make spinning up a new session a one-liner.

---

## Stack

| Tool            | Role                                                 |
| --------------- | ---------------------------------------------------- |
| **tmux**        | Terminal multiplexer — sessions, windows, panes      |
| **tmuxinator**  | Session templates — reproducible layouts via YAML    |
| **oh-my-tmux**  | tmux config framework (theming, sane defaults)       |
| **Claude Code** | AI agent (`claude` CLI)                              |
| **Neovim**      | Editor, integrated with tmux for seamless navigation |
| **lazygit**     | Git TUI                                              |

---

## Session Layout

Every session follows the same four-window pattern:

```
Session: <project-name>
├── Window 1: claude    → AI agent REPL
├── Window 2: editor    → nvim
├── Window 3: lazygit   → git TUI
└── Window 4: shell     → free terminal
```

Running multiple projects means multiple sessions — each isolated, each with the same layout, all accessible from a single terminal.

```
Sessions:
  api-refactor     → claude | nvim | lazygit | shell
  frontend-feature → claude | nvim | lazygit | shell
  infra-work       → claude | nvim | lazygit | shell
```

---

## tmuxinator Templates

The `mux` alias wraps tmuxinator:

```zsh
alias mux=tmuxinator
```

### `task.yaml` — WSL / Linux projects

For projects living on the WSL filesystem. All tools are the WSL-side installs.

```yaml
name: <%= @args[0] || "task" %>
root: <%= @args[1] || ENV["PWD"] %>

windows:
    - claude:
          - claude
    - editor:
          - nvim
    - lazygit:
          - lazygit
    - shell:
```

**Usage:**

```sh
# From the project directory
mux task my-api

# From anywhere
mux task my-api /home/mzawisa/projects/my-api
```

### `windev.yaml` — Windows filesystem projects

For projects on the Windows side (e.g. `C:\Users\mzawisa\source\ProjectName`). All panes launch PowerShell 7 and navigate to the Windows path. Tools (nvim, lazygit, claude) are the Windows-installed versions.

```yaml
name: <%= @args[0] || "windev" %>
root: <%= wsl_path %> # tmuxinator needs a WSL path; auto-converted

windows:
    - claude: → pwsh → Set-Location 'C:\...' → claude
    - editor: → pwsh → Set-Location 'C:\...' → nvim .
    - lazygit: → pwsh → Set-Location 'C:\...' → lazygit
    - shell: → pwsh → Set-Location 'C:\...'
```

Path conversion is handled by ERB at template-parse time — you can pass either format:

```sh
mux windev my-app 'C:\Users\mzawisa\source\ProjectName'
# or
mux windev my-app /mnt/c/Users/mzawisa/source/ProjectName
```

The `-NoExit` flag means closing a tool (e.g. quitting nvim) drops you to an interactive PS prompt in the project directory rather than closing the pane.

---

## Key Bindings

Prefix is `Ctrl+a` (remapped from the default `Ctrl+b`).

### Navigating between windows

| Key        | Action                   |
| ---------- | ------------------------ |
| `Ctrl+a j` | Go to window 1 (claude)  |
| `Ctrl+a k` | Go to window 2 (editor)  |
| `Ctrl+a l` | Go to window 3 (lazygit) |
| `Ctrl+a ;` | Go to window 4 (shell)   |

These match the 4-window layout, so muscle memory transfers across every session.

### Navigating between sessions

| Key        | Action                              |
| ---------- | ----------------------------------- |
| `Ctrl+a 9` | Previous session                    |
| `Ctrl+a 0` | Next session                        |
| `Ctrl+a s` | Session picker (oh-my-tmux default) |

### Pane management

| Key                   | Action                                   |
| --------------------- | ---------------------------------------- |
| `Ctrl+a 5`            | Split vertically                         |
| `Ctrl+a "`            | Split horizontally                       |
| `Ctrl+a h/j/k/l`      | Resize pane                              |
| `Ctrl+a H/J/K/L`      | Resize pane (larger steps)               |
| `Ctrl+w Ctrl+h/j/k/l` | Navigate panes (shared with nvim splits) |

### Other

| Key        | Action                                |
| ---------- | ------------------------------------- |
| `Ctrl+a R` | Reload tmux config                    |
| `Ctrl+a z` | Zoom current pane (fullscreen toggle) |

---

## Neovim Integration

`vim-tmux-navigator` makes pane navigation seamless — the same `Ctrl+w Ctrl+h/j/k/l` keys move between nvim splits and tmux panes without noticing the boundary.

```lua
-- nvim: Ctrl+w + Ctrl+direction navigates transparently into tmux panes
{ "<c-w><c-h>", "<cmd>TmuxNavigateLeft<cr>" },
{ "<c-w><c-j>", "<cmd>TmuxNavigateDown<cr>" },
{ "<c-w><c-k>", "<cmd>TmuxNavigateUp<cr>" },
{ "<c-w><c-l>", "<cmd>TmuxNavigateRight<cr>" },
```

---

## Typical Workflow

Each tmux session lives in its own Windows Terminal tab. Switching between projects is just `Ctrl+Tab` — no tmux session picker needed.

```sh
# Open a new terminal tab for each workstream, then:
mux task api-refactor ~/projects/api
mux task frontend-feature ~/projects/frontend
mux windev windows-service 'C:\source\WindowsService'
```

```
Tab 1: api-refactor      → Ctrl+Tab →  Tab 2: frontend-feature  → Ctrl+Tab →  Tab 3: windows-service
  claude | nvim | lazygit | shell         claude | nvim | lazygit | shell        claude | nvim | lazygit | shell
```

Switching between tabs feels like switching between projects. Within a tab, the window bindings handle the rest:

```
Ctrl+a j   # jump to claude window
Ctrl+a k   # jump to editor
Ctrl+a l   # jump to lazygit
Ctrl+a ;   # jump to shell
```

Each Claude instance has its own context and works independently. The editor and lazygit windows let you review changes or feed context back to the agent without leaving the tab.

---

## Dotfiles

| File                                 | Purpose                                |
| ------------------------------------ | -------------------------------------- |
| `dotfiles/tmux.conf.local`           | oh-my-tmux overrides (theme, bindings) |
| `dotfiles/tmuxinator/task.yaml`      | WSL session template                   |
| `dotfiles/tmuxinator/windev.yaml`    | Windows session template               |
| `dotfiles/nvim/lua/plugins/tmux.lua` | vim-tmux-navigator config              |
| `dotfiles/zsh/.zshrc`                | `mux` and `pwsh` aliases               |

Tmuxinator templates are symlinked from `~/.config/tmuxinator/` into the dotfiles repo for version control.
