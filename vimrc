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

set background=dark
"colorscheme desert " Sets the default color scheme.
set textwidth=80 " Sets the text width.
set wrap " Enable line wrapping.
if exists('+colorcolumn') " Adds color column at 80 characters.
  set colorcolumn=80
endif
set title " Sets the title of the window to the current file name.
set showmatch " Highlight matching parenthesis.


" Miscellaneous Options
set history=1000 " Increase history.
set showcmd " Show partial commands.
set wildmenu " Allows tab completion in menu.
set cmdheight=2 " Sets menu height to 2 lines.
set autoread " Reload files if changed externally.


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
vnoremap("J", ":m '>+1<CR>gv=gv")
vnoremap("K", ":m '<-2<CR>gv=gv")


" Powerline
" set rtp+=/usr/local/lib/python3.9/site-packages/powerline/bindings/vim


" Airline
set laststatus=2
set encoding=utf-8

let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

let g:airline_symbols.space = "\ua0"
let g:airline_symbols.colnr = ' '
" Airline customization
let g:airline_theme = 'simple'
let g:airline#extensions#branch#enabled=1
let g:airline#extensions#whitespace#enabled=1
" Airline Tabline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_splits = 1
let g:airline#extensions#tabline#show_buffers = 1
"let g:airline#extensions#tabline#show_tabs=0
let g:airline#extensions#tabline#switch_buffers_and_tabs = 1
let g:airline#extensions#tabline#buffer_idx_mode = 1
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>0 <Plug>AirlineSelectTab0
nmap <leader>- <Plug>AirlineSelectPrevTab
nmap <leader>t <Plug>AirlineSelectNextTab
nmap <leader>q <Esc>:tabclose<CR>

nmap <leader>rw <CMD>Explore<CR>
nmap <leader>ff <CMD>FZF<CR>
