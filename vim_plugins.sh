#  Install css-color:
git clone https://github.com/ap/vim-css-color.git ~/.vim/pack/css-color/start/css-color

# Install Vim Airline
mkdir ~/.vim/pack/dist/start
cd ~/.vim/pack/dist/start
git clone https://github.com/vim-airline/vim-airline
vim -u NONE -c "helptags vim-airline/doc" -c q
echo "Make sure \"let g:airline_powerline_fonts=1\" is in your .vimrc"

# Install Vim Airline Themes:
mkdir -p ~/.vim/pack/dist/start
cd ~/.vim/pack/dist/start
git clone https://github.com/vim-airline/vim-airline-themes
vim -u NONE -c "helptags vim-airline-themes/doc" -c q
# echo "Remember to run :helptags ~/.vim/pack/dist/start/vim-airline-themes/doc"

# Install Vim Fugitive:
mkdir -p ~/.vim/pack/tpope/start
cd ~/.vim/pack/tpope/start
git clone https://tpope.io/vim/fugitive.git
vim -u NONE -c "helptags fugitive/doc" -c q

# Install Vim Gitgutter
mkdir -p ~/.vim/pack/airblade/start
cd ~/.vim/pack/airblade/start
git clone https://github.com/airblade/vim-gitgutter.git
vim -u NONE -c "helptags vim-gitgutter/doc" -c q
