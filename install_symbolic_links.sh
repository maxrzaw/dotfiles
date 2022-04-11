# Creates symbolic links to the dotfiles repo from ~
ln -s ./bashrc ~/.bashrc
ln -s ./vimrc ~/.vimrc
ln -s ./gitconfig ~/.gitconfig
ln -s ./bash_aliases ~/.bash_aliases
mkdir -p ~/.vim
ln -s ~/dotfiles/ftplugin ~/.vim/ftplugin
