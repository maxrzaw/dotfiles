#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
NEOVIM_DIR="${NEOVIM_DIR:-$HOME/source/neovim}"
FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
BASHRC_FILE="${BASHRC_FILE:-$HOME/.bashrc}"

log() {
  printf '\n==> %s\n' "$1"
}

append_if_missing() {
  local file="$1"
  local marker="$2"
  local content="$3"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fq "$marker" "$file"; then
    printf '\n%s\n' "$content" >> "$file"
  fi
}

require_command() {
  local command_name="$1"
  local package_name="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s (package: %s)\n' "$command_name" "$package_name" >&2
    exit 1
  fi
}

log "Installing apt packages"
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  cmake \
  curl \
  fd-find \
  gettext \
  git \
  ninja-build \
  openssh-client \
  pkg-config \
  ripgrep \
  unzip

require_command git git
require_command curl curl

log "Installing dotfiles"
bash "$DOTFILES_DIR/make_links.sh"

if ! command -v fnm >/dev/null 2>&1 && [ ! -x "$FNM_DIR/fnm" ]; then
  log "Installing fnm"
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell
fi

append_if_missing \
  "$BASHRC_FILE" \
  "# fnm setup" \
  "# fnm setup\nexport PATH=\"$FNM_DIR:\$PATH\"\neval \"\$(fnm env --use-on-cd --shell bash)\""

export PATH="$FNM_DIR:$PATH"
eval "$("$FNM_DIR/fnm" env --shell bash)"

log "Installing Node.js LTS"
fnm install --lts
fnm use lts-latest
fnm default "$(node -v)"

log "Installing npm neovim package"
npm install -g neovim

if [ ! -d "$NEOVIM_DIR/.git" ]; then
  log "Cloning Neovim"
  mkdir -p "$(dirname "$NEOVIM_DIR")"
  git clone --depth 1 --branch stable https://github.com/neovim/neovim "$NEOVIM_DIR"
else
  log "Updating Neovim source"
  git -C "$NEOVIM_DIR" fetch origin stable --depth 1
  git -C "$NEOVIM_DIR" checkout stable
  git -C "$NEOVIM_DIR" pull --ff-only origin stable
fi

log "Building Neovim"
make -C "$NEOVIM_DIR" distclean
make -C "$NEOVIM_DIR" CMAKE_BUILD_TYPE=Release

log "Installing Neovim"
sudo make -C "$NEOVIM_DIR" install

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  log "Linking fd to fdfind"
  sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

log "Done"
printf 'Neovim source: %s\n' "$NEOVIM_DIR"
printf 'Dotfiles directory: %s\n' "$DOTFILES_DIR"
