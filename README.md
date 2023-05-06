# dotfiles

## Quick Start

Execute `make_links.sh` to set up gitconfig, bashrc, vimrc, powerline, and nvim.

Add the following line into your system .bashrc to source the common bashrc

```bash
if [ -f ~/dotfiles/bashrc ]; then
    . ~/dotfiles/bashrc
fi
```

Add the following line into your system .gitconfig

```
[include]
    path = ~/dotfiles/gitconfig
```
