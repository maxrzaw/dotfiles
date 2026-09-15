# Dotfiles Project Overview

This repository contains a highly customized development environment for macOS (with support for Windows/WSL). It is centered around a fast, terminal-centric workflow using Zsh, Neovim, and Tmux.

## Core Components & Technologies

- **Shell:** `zsh` with Powerlevel10k (`.p10k.zsh`, `p10k.custom.zsh`).
- **Editor:** Neovim (`nvim/`) configured with `lazy.nvim` and `catppuccin`. Supports VS Code integration via `vscode-neovim`.
- **Terminal Emulators:** Wezterm (`wezterm/`), Ghostty (`ghostty/`) and Windows Terminal.
- **Multiplexer:** Tmux (`tmux.conf.local`) with `oh-my-tmux` and `tmuxinator` for session management.
- **Keyboard:** QMK/ZMK hints in Neovim.
- **Git:** Extensive aliases and global configuration (`gitconfig`).

## Key Files & Directory Structure

- `make_links.sh`: Setup script to symlink dotfiles to `~/.config`. Not maintained.
- `zsh/.zshrc`: Main shell configuration.
- `nvim/init.lua`: Entry point for Neovim configuration.
- `tmux.conf.local`: Customizations for the `oh-my-tmux` framework.
- `tmuxinator/`: YAML templates for project-specific tmux sessions (e.g., `task.yaml`, `windev.yaml`).

## Setup and Installation

1.  **Symlink Configs:** Run `./make_links.sh` to create symbolic links in `~/.config/`.
2.  **Git Config:** The script automatically adds `include.path ~/dotfiles/gitconfig` to your `~/.gitconfig`.
3.  **Neovim:** Uses `lazy.nvim`. On first launch, it will automatically clone and install plugins.
4.  **Zsh:** Requires Powerlevel10k. Custom segments (like AWS token validity) are in `zsh/p10k.custom.zsh`.

## Development Workflows

### AI Agent Workflow (tmuxinator)

The environment is optimized for running multiple AI agents (like Claude Code) using `tmuxinator`.

- Use `mux task <name> [path]` to spin up a standardized 4-window environment:
    - 1 `claude`: AI agent REPL
    - 2 `editor`: Neovim
    - 3 `lazygit`: Git TUI
    - 4 `shell`: General purpose terminal

### Neovim Conventions

- **Leader Key:** `<Space>` (implied by common `lazy.nvim` setups and `mzawisa.set`).
- **Escaping:** `jk` in insert mode maps to `<ESC>`.
- **System Clipboard:** `<leader>y` to yank to system clipboard.
- **Formatting:** `<leader>ft` to toggle auto-formatting.
- **Navigation:** Seamless navigation between Neovim splits and Tmux panes using `Ctrl+h/j/k/l` (via `vim-tmux-navigator`).

### Git Aliases

- `git st`: Status
- `git aa`: Add all
- `git cm`: Commit
- `git lg`: LazyGit (if installed)
- `git plog`: Pretty graph log

## Usage Notes

- **AWS Token Monitoring:** A background daemon (`aws_token_daemon.py`) monitors AWS credentials and updates the Zsh prompt via a cache file in `/tmp/`.
- **Windows Support:** Some configurations (like `wezterm.lua` and `tmuxinator/windev.yaml`) include specific logic for Windows filesystem paths and PowerShell.

## Troubleshooting

### Mason `roslyn` package fails to install/update (wget exit code 8)

Mason's `roslyn` package (`nvim/lua/plugins/mason.lua`) comes from the
`crashdummyy/mason-registry` (configured in `nvim/lua/plugins/mason.lua`), which
sometimes pins `roslyn` to a GitHub release tag that has no uploaded assets. When
that happens, `:MasonInstall roslyn` (or Mason's own `ensure_installed` auto-install
on startup) fails with `wget failed with exit code 8` — an HTTP error (404) fetching
the asset zip, not a network blip, so retrying the same command won't help. Whatever
binary was already on disk before the failed update stays in place, stale — which is
how this often first shows up as the Roslyn LSP refusing to start (e.g. `Unrecognized
command or argument '--daemon-mode'`, because `roslyn.nvim` always passes that flag
but an old binary predates daemon-mode support).

To fix without editing the registry or `mason.lua`, pin a known-good version directly:

1. Check the `roslyn-nightly` entry in the same registry file
   (`~/.local/share/nvim/mason/registries/github/crashdummyy/mason-registry/registry.json`)
   for its `source.id` version — it tracks upstream more closely and is usually intact.
2. Confirm that version's Linux asset actually resolves (302, not 404):
   `curl -sI "https://github.com/Crashdummyy/roslynLanguageServer/releases/download/<version>/microsoft.codeanalysis.languageserver.linux-x64.zip"`
3. Run `:MasonInstall roslyn@<version>` in Neovim — this pins the working release
   under the existing `roslyn` package name, so `ensure_installed = { "roslyn" }`
   stays valid and no config file needs to change.

Don't reinstall plain `roslyn` (no version) afterward — that reverts to whatever
broken version the registry currently pins.
