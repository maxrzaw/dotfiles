# Herdr Select Plugin

Fast local Herdr selector plugin for arbitrary-key indexed navigation.

## Install

From the dotfiles repo:

```sh
cargo build --release --manifest-path herdr/plugins/select/Cargo.toml
herdr plugin link "$PWD/herdr/plugins/select"
herdr server reload-config
```

Verify:

```sh
herdr plugin list
herdr plugin action list --plugin dotfiles.select
herdr config check
```

## Current Bindings

- `prefix+j/k/l/semicolon`: tabs 1-4 in the current workspace
- `prefix+shift+j/k/l/semicolon`: workspaces 1-4
- `prefix+alt+j/k/l/semicolon`: agents 1-4

## Notes

- The plugin is macOS/Linux only for now.
- Build output lives under `target/` and is ignored by git.
- The plugin is linked locally from this repo; after moving the repo, relink it.
- The binary can also be run as `herdr-select tab 1`, `herdr-select workspace 1`, or `herdr-select agent 1` when `HERDR_SOCKET_PATH` is set by Herdr.
