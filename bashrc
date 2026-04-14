# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

if [ -x "$(command -v nvim)" ]; then
    export EDITOR=nvim
    export GIT_EDITOR=nvim
else
    export EDITOR=vim
    export GIT_EDITOR=vim
fi

# Alias definitions are in bash_aliases.
if [ -f ~/dotfiles/bash_aliases ]; then
    . ~/dotfiles/bash_aliases
fi

# Git-Bash Completion
if [ -f ~/.git-completion.bash ]; then
    . ~/.git-completion.bash
fi
