" Max Zawisa's .vimrc

set nocompatible " only use this .vimrc.
filetype plugin indent on

" Indentation Options
set expandtab " This expands tabs into spaces.
set tabstop=4 " this sets tab width to 4 spaces
set softtabstop=4 
set shiftwidth=4 " When shifting, indent using 4 spaces.
set autoindent " new lines inherit the indentation of previous lines.
set smartindent
set smarttab

" Search Options
set hlsearch " This highlights search results.
set ignorecase " This ignores case when searching.
set incsearch " Show incremental searches.
set smartcase " Switch to case sensitive when uppercase is present in search.

if has('mouse')
  set mouse=a
endif

" User Interface Options
set number " Turns on line numbers.
syntax on " Turns on syntax highlighting.
set background=dark
colorscheme desert " Sets the default color scheme.
set textwidth=80 " Sets the text width.
set wrap " Enable line wrapping.
if exists('+colorcolumn') " Adds color column at 80 characters.
  set colorcolumn=80
endif
set title " Sets the title of the window to the current file name.
set showmatch " Highlight matching parenthesis.

" Miscellaneous Options
set history=1000 " Increase history.
set spell " Turns on spell check.
set showcmd " Show partial commands.
set wildmenu " Allows tab completion in menu.
set cmdheight=2 " Sets menu height to 2 lines.
set autoread " Reload files if changed externally.
"the next two lines make ; act like : so that you don't have to 
"use ;; for ; instead
map ; :
noremap ;; ;
" Maps jk to <ESC> when in insert mode
inoremap jk <ESC> 
