set number " this turns on line numbers

filetype plugin indent on
set expandtab
set tabstop=4 " this sets tab width to 4 spaces
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent


syntax on
colorscheme desert

set textwidth=80
set background=dark
map ; :
 "this line and the next line make ; act like : so that you don't have to 
"use ;; for ; instead
noremap ;; ;
