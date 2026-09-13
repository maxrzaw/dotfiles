#!/usr/bin/env bash

set -euo pipefail

NEOVIM_DIR="${NEOVIM_DIR:-$HOME/source/neovim}"
REPOSITORY="https://github.com/neovim/neovim.git"
REQUESTED_TAG="${1:-}"

log() {
  printf '\n==> %s\n' "$1"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_command git
require_command make
require_command sudo

if [[ $# -gt 1 || "$REQUESTED_TAG" == "--help" || "$REQUESTED_TAG" == "-h" ]]; then
  printf 'Usage: %s [vX.Y.Z]\n' "${0##*/}"
  printf 'Build and install the newest stable Neovim release, or the specified release tag.\n'
  exit 0
fi

if [[ ! -d "$NEOVIM_DIR/.git" ]]; then
  log "Cloning Neovim"
  mkdir -p "$(dirname "$NEOVIM_DIR")"
  git clone "$REPOSITORY" "$NEOVIM_DIR"
fi

if [[ -n "$(git -C "$NEOVIM_DIR" status --porcelain)" ]]; then
  printf 'Neovim source checkout has uncommitted changes: %s\n' "$NEOVIM_DIR" >&2
  exit 1
fi

log "Fetching Neovim release tags"
git -C "$NEOVIM_DIR" fetch --force --tags origin

TAG="$REQUESTED_TAG"
if [[ -z "$TAG" ]]; then
  while IFS= read -r candidate; do
    if [[ "$candidate" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      TAG="$candidate"
      break
    fi
  done < <(git -C "$NEOVIM_DIR" tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-version:refname)
fi

if [[ -z "$TAG" ]]; then
  printf 'Could not determine the latest stable Neovim tag.\n' >&2
  exit 1
fi

if ! git -C "$NEOVIM_DIR" rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
  printf 'Neovim tag does not exist: %s\n' "$TAG" >&2
  exit 1
fi

log "Checking out $TAG"
git -C "$NEOVIM_DIR" checkout --detach "$TAG"

log "Building Neovim $TAG"
make -C "$NEOVIM_DIR" distclean
make -C "$NEOVIM_DIR" CMAKE_BUILD_TYPE=Release

log "Installing Neovim $TAG"
sudo make -C "$NEOVIM_DIR" install

printf '\nInstalled Neovim %s from %s\n' "$TAG" "$NEOVIM_DIR"
