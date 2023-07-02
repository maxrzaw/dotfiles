# Set editor
VIM="vim"
if [ -x "$(command -v nvim)" ]; then
    VIM="nvim"
    alias vimdiff="nvim -d"
fi
git config --global core.editor $VIM
alias vim=$VIM
export EDITOR=$VIM
export GIT_EDITOR=$VIM

alias got='git'

setopt correct
setopt globdots
setopt histignoredups

# use vi mode
bindkey -M viins 'jk' vi-cmd-mode
# INSERT_MODE_INDICATOR="%F{yellow}+%f"
if [ -x "$(command -v lazygit)" ]; then
    alias lg=lazygit
fi
