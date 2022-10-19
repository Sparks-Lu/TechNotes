set nocompatible              " be iMproved, required
filetype off                  " required
colorscheme ron

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
Bundle 'Valloric/YouCompleteMe'
Plugin 'tmhedberg/SimpylFold'
Plugin 'vim-scripts/indentpython.vim'
Plugin 'vim-scripts/mru.vim'
Plugin 'vim-syntastic/syntastic'
Plugin 'nvie/vim-flake8'
Plugin 'jnurmine/Zenburn'
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line


" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set smartcase		" Do smart case matching
set incsearch		" Incremental search
"set autowrite		" Automatically save before commands like :next and :make
"set hidden             " Hide buffers when they are abandoned
"set mouse=a		" Enable mouse usage (all modes)

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif

" Set some options, :options for help
set nobackup
set laststatus=2    " Always show status line
set statusline=%F%m%r%h%w%=[%l/%L,%v]
set hlsearch
set ai
set ic
set sw=4        " shift width
set ts=4        " tab stop
set smarttab    " tab insert blank the same as shiftwidth
set expandtab   " Insert spaces when user input tab
set smartcase
set showmatch
set wildmenu         " Enhenced command line completion
set wildignore=*.o
set showmode         " Show current mode (inser, visual, ...)
set showfulltag     " Show full tag when completing
set complete=k,.,i,t     " Keyword completion search order and scope
set diffopt=filler,iwhite       " Ignore whitespace when diff
set foldmethod=indent
set foldlevel=99
set clipboard=unnamed

nnoremap s :w<CR>
nnoremap <SPACE> <C-F>
nnoremap ; <C-B>
noremap <C-P> <Esc>:bp<CR>
noremap <C-N> <Esc>:bn<CR>
nnoremap <C-J> i<C-J><Esc>

let mapleader=","

nnoremap <Leader>o o<ESC>
nnoremap <silent> <Leader>w :w<CR>
" Switch between windows
nnoremap <Leader>, <C-W>w
" Maximize current horizontally half-split window
nnoremap <C-W>m 15<C-W>+ 50<C-W>>
" No highlight
nnoremap <silent> <Leader>. :noh<CR>
" For easier use of fold
" nnoremap <silent> <Leader>f :setlocal foldmethod=indent<CR>
nnoremap <silent> <Leader>y :saveas! /tmp/junk<CR>:bp<CR>
nnoremap <silent> <Leader>p :r /tmp/junk<CR>
nnoremap <silent> <Leader>cd :cd %:p:h<CR>
" Yank file name of current buffer
nnoremap <silent> <Leader>yfn :let @@=expand("%:p")<CR>

" Change the working directory to the directory containing the current file
" autocmd BufEnter * :lcd %:p:h
" Only c,cpp,h ts=4
autocmd FileType c,cpp,h,java,python setlocal foldmethod=indent foldenable expandtab cindent ts=4 sw=4 smartindent autoindent
autocmd FileType c,cpp,h iab #i #include
autocmd FileType c,cpp,h iab #d #define
" Write file and make
autocmd FileType c,cpp,h nnoremap <Leader>m :w<CR> :make<CR>
" Execute executable file in currect directory
autocmd FileType c,cpp,h nnoremap <Leader>run :!find . -type f -perm +1 -exec {} \;<CR>
" Keyword completion
autocmd FileType c,cpp,h setlocal dict+=~/.vim/dict/qt
autocmd BufNewFile,BufRead *.js,*.html,*.css,*.vue setlocal ts=2 sw=2 expandtab smartindent
autocmd BufNewFile,BufRead *.py set textwidth=79
autocmd BufRead,BufNewFile *.pw,*.cpp,*.h match BadWhitespace /\s\+$/

cab vd vert diffsplit

if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif


"-----------------PLUGIN RELATED----------------
" For taglist plugin
autocmd FileType c,cpp,h,java nnoremap <silent> <Leader>t :Tlist<CR> <C-W>w
autocmd FileType c,cpp,h,java let Tlist_Auto_Open=1
let Tlist_WinWidth=20
let Tlist_Exit_OnlyWindow=1
let Tlist_Enable_Fold_Column=0
let tlist_cpp_settings='c++;f:function'
let Tlist_Sort_Type="name"
let Tlist_Show_One_File=1

" MRU plugin
nnoremap <silent> <Leader>r :MRU<cr> 
let MRU_Max_Entries=100

" YouCompleteMe plugin
let g:ycm_autoclose_preview_window_after_completion=1
map <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>

" NERDTree plugin
let NERDTreeIgnore=['\.pyc$', '\~$']


" Python
iab inp import numpy as np
iab icv import cv2 as cv
iab iplt import matplotlib.pyplot as plt
iab pmain if __name__ == '__main__':<CR>main()
let python_hight_all=1
syntax on

