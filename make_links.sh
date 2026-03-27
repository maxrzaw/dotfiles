# Creates symbolic links to the dotfiles repo from ~
mkdir -p ~/.config/
if [ ! -L ~/.config/nvim ]; then
    ln -s ~/dotfiles/nvim ~/.config/nvim
    echo "Created symbolic link from ~/.config/nvim to ~/dotfiles/nvim"
fi

# if [ ! -d ~/.config/powerline ]; then
#     ln -s ~/dotfiles/powerline ~/.config/powerline
#     echo "Created symbolic link from ~/.config/powerline to ~/dotfiles/powerline"
# fi

# Set up oh-my-tmux
if [ ! -d ~/.tmux ]; then
    git clone https://github.com/gpakosz/.tmux ~/.tmux
    echo "Cloned oh-my-tmux to ~/.tmux"
fi
if [ ! -L ~/.tmux.conf ]; then
    ln -s ~/.tmux/.tmux.conf ~/.tmux.conf
    echo "Created symbolic link from ~/.tmux.conf to ~/.tmux/.tmux.conf"
fi
if [ ! -L ~/.tmux.conf.local ]; then
    ln -s ~/dotfiles/tmux.conf.local ~/.tmux.conf.local
    echo "Created symbolic link from ~/.tmux.conf.local to ~/dotfiles/tmux.conf.local"
fi

# Set up tmuxinator
mkdir -p ~/.config
if [ ! -d ~/.config/tmuxinator ]; then
    ln -s ~/dotfiles/tmuxinator ~/.config/tmuxinator
    echo "Created symbolic link from ~/.config/tmuxinator to ~/dotfiles/tmuxinator"
fi

# Set up zsh
if [ ! -L ~/.zshrc ]; then
    ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
    echo "Created symbolic link from ~/.zshrc to ~/dotfiles/zsh/.zshrc"
fi
if [ ! -L ~/.p10k.zsh ]; then
    ln -s ~/dotfiles/zsh/.p10k.zsh ~/.p10k.zsh
    echo "Created symbolic link from ~/.p10k.zsh to ~/dotfiles/zsh/.p10k.zsh"
fi

# Set up some includes
#touch ~/.vimrc
#if test $(grep -c "~/dotfiles/vimrc" ~/.vimrc) = 0; then
#    echo "Adding vimrc to ~/.vimrc"
#    echo "source ~/dotfiles/vimrc" >> ~/.vimrc
#fi

#touch ~/.bashrc
if test $(grep -c "~/dotfiles/bashrc" ~/.bashrc) = 0; then
    echo "Adding bashrc to ~/.bashrc"
    echo -e "if [ -f ~/dotfiles/bashrc ]; then\n    . ~/dotfiles/bashrc\nfi" >> ~/.bashrc
fi

touch ~/.gitconfig
if test $(grep -c "~/dotfiles/gitconfig" ~/.gitconfig) = 0; then
    echo "Adding gitconfig to ~/.gitconfig"
    git config --global include.path ~/dotfiles/gitconfig
fi
