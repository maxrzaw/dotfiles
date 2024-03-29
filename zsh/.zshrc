# Set editor
VIM="vim"
if [ -x "$(command -v nvim)" ]; then
    VIM="nvim"
    alias vimdiff="nvim -d"
fi
git config --global core.editor $VIM
alias vim=$VIM
alias mux=tmuxinator
export EDITOR=$VIM
export GIT_EDITOR=$VIM

alias got='git'

setopt correct
setopt globdots
setopt histignoredups

# use vi mode
bindkey -M viins 'jk' vi-cmd-mode
# INSERT_MODE_INDICATOR="%F{yellow}+%f"
if [ -x "$(command -v lazydocker)" ]; then
    alias ld=lazydocker
fi
if [ -x "$(command -v lazygit)" ]; then
    alias lg=lazygit
fi

# Better completion
# This allows for case insensitive completion as a fallback
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
# autoload -Uz compinit && compinit

# Kubernetes
if [ -x "$(command -v kubectl)" ]; then
    source <(kubectl completion zsh)
    alias k=kubectl
fi
