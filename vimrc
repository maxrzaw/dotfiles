" Max Zawisa's .vimrc

set nocompatible " only use this .vimrc.

" Syntax and indentation
filetype plugin indent on
syntax on " Turns on syntax highlighting.
set foldmethod=syntax

" Indentation Options
set expandtab " This expands tabs into spaces.
set tabstop=4 " this sets tab width to 4 spaces
set softtabstop=4
set shiftwidth=4 " When shifting, indent using 4 spaces.
set autoindent " new lines inherit the indentation of previous lines.
set smartindent
set smarttab
set list
set listchars=tab:▸\ ,trail:.


" Search Options
set hlsearch " This highlights search results.
set ignorecase " This ignores case when searching.
set incsearch " Show incremental searches.
set smartcase " Switch to case sensitive when uppercase is present in search.


" Mouse
if has('mouse')
  set mouse=a
endif


" User Interface Options
set number " Turns on line numbers.
set relativenumber

set background=dark
"colorscheme desert " Sets the default color scheme.
set textwidth=120 " Sets the text width.
set nowrap " Enable line wrapping.
if exists('+colorcolumn') " Adds color column at 80 characters.
  set colorcolumn=120
endif
set title " Sets the title of the window to the current file name.
set showmatch " Highlight matching parenthesis.
set scrolloff=8
set sidescrolloff=8


" Miscellaneous Options
set history=1000 " Increase history.
set showcmd " Show partial commands.
set wildmenu " Allows tab completion in menu.
set cmdheight=2 " Sets menu height to 2 lines.
set autoread " Reload files if changed externally.
set signcolumn=yes
set shortmess+=W
set shortmess+=c
set shortmess+=C
set nobackup
set nowritebackup
set updatetime=300
set timeoutlen=500
set exrc
set undofile
set undodir=~/.vim/undodir
set ruler

" netrw
let g:netrw_bufsettings = "noma nomod nonu nobl nowrap ro rnu"
let g:netrw_preview = 1
let g:netrw_winsize = 40
let g:netrw_altfile = 1
let g:netrw_keepj = "keepj"


" Mappings
" Set <leader> to Space
let mapleader = " "

" The next two lines make ; act like : so that you don't have to
" use ;; for ; instead
map ; :
noremap ;; ;
" Maps jk to <ESC> when in insert mode
inoremap jk <ESC>
set backspace=indent,eol,start

" Moving lines
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv


nmap <leader>e <CMD>Explore<CR>
