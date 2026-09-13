# dotfiles

My . files

# Setting up a new Mac

- Add a ~/.gitconfig file
- Install homebrew
- Install node via nvm
- Install python with homebrew
- Install neovim from source

## Updating Neovim

`./update_neovim.sh` fetches the latest stable Neovim release tag, builds it in
Release mode, and installs it. Pass a tag to select a release, such as
`./update_neovim.sh v0.12.5`. By default it uses `~/source/neovim`; set
`NEOVIM_DIR` to use another source checkout.
