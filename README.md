# dotfiles

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
