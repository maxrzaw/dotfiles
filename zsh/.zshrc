# Set editor
VIM="vim"
if [ -x "$(command -v nvim)" ]; then
    VIM="nvim"
    alias vimdiff="nvim -d"
fi
git config --global core.editor $VIM
alias vim=$VIM
alias mux=tmuxinator

# Custom tmuxinator/mux completion that adds directory completion for extra args
_mux() {
  local commands projects
  commands=(${(f)"$(tmuxinator commands zsh 2>/dev/null)"})
  projects=(${(f)"$(tmuxinator completions start 2>/dev/null)"})

  if (( CURRENT == 2 )); then
    _alternative \
      'commands:: _describe -t commands "tmuxinator subcommands" commands' \
      'projects:: _describe -t projects "tmuxinator projects" projects'
  elif (( CURRENT == 3 )); then
    case $words[2] in
      copy|cp|c|debug|delete|rm|open|o|start|s|edit|e)
        _arguments '*:projects:($projects)'
      ;;
    esac
  elif (( CURRENT >= 4 )); then
    case $words[CURRENT] in
      /*|~*|.*)
        _directories
      ;;
    esac
  fi
}
compdef _mux tmuxinator mux
alias wtitle="wezterm cli set-tab-title"

export EDITOR=$VIM
export GIT_EDITOR=$VIM

alias got='git'
alias pip=pip3
alias python=python3

# This works with wezterm/mzawisa/workspaces.lua
wez() {
    printf "\033]1337;SetUserVar=%s=%s\007" user-workspace-command `echo -n $1 | base64`
}

# This is the default, but with the truncation limit increased
export ZSH_THEME_TERM_TAB_TITLE_IDLE="%50<..<%~%<<"

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
if [[ ! -v NEOVIM_WORK ]] then
    if [ -x "$(command -v kubectl)" ]; then
        source <(kubectl completion zsh)
        alias k=kubectl
    fi
fi
