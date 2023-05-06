# Creates symbolic links to the dotfiles repo from ~
mkdir -p ~/.config/
if [ ! -d ~/.config/nvim ]; then
    ln -s ~/dotfiles/nvim/config/nvim ~/.config/nvim
    echo "Created symbolic link from ~/.config/nvim to ~/dotfiles/nvim/config/nvim"
fi

if [ ! -d ~/.config/powerline ]; then
    ln -s ~/dotfiles/powerline ~/.config/powerline
    echo "Created symbolic link from ~/.config/powerline to ~/dotfiles/powerline"
fi

# Set up come includes
touch ~/.vimrc
if test $(grep -c "~/dotfiles/vimrc" ~/.vimrc) = 0; then
    echo "Adding vimrc to ~/.vimrc"
    echo "source ~/dotfiles/vimrc" >> ~/.vimrc
fi

touch ~/.bashrc
if test $(grep -c "~/dotfiles/bashrc" ~/.bashrc) = 0; then
    echo "Adding bashrc to ~/.bashrc"
    echo -e "if [ -f ~/dotfiles/bashrc ]; then\n    . ~/dotfiles/bashrc\nfi" >> ~/.bashrc
fi

if test $(grep -c "/dotfiles/gitconfig" ~/.gitconfig) = 0; then
    echo "Adding gitconfig to ~/.gitconfig"
    git config --global include.path ~/dotfiles/gitconfig
fi
