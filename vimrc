set number " this turns on line numbers

filetype plugin indent on
set expandtab
set tabstop=4 " this sets tab width to 4 spaces
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent
set smarttab
set et

if has('mouse')
  set mouse=a
endif

syntax on
colorscheme desert

set textwidth=80
set wrap
set background=dark

if exists('+colorcolumn')
  set colorcolumn=81
endif


map ; :
 "this line and the next line make ; act like : so that you don't have to 
"use ;; for ; instead
noremap ;; ;

if (&filetype=='c' || &filetype=='cpp')
    iabbrev #i #include
    iabbrev ustd using namespace std;
    iabbrev main int main(int argc, char * argv[]) { }
    iabbrev cout std::cout
    iabbrev cin std::cin
    iabbrev string std::string
endif

