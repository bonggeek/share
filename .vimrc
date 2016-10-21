" ===============================================================================
" Vimrc - Abhinaba Basu http://www.abhinaba.com
" ===============================================================================

" Show fancy colors =============================================================
syn on                              " Syntax highlighting on
colorscheme morning                " choose a darker color scheme

if has("gui_running")
        set guifont=Consolas:h12 " use this font 
        set lines=50                " height = 50 lines
        set columns=120             " width = 150 columns
        "Cursor settings
        highlight Cursor guifg=white guibg=red
        highlight iCursor guifg=white guibg=steelblue
        set guicursor=n-v-c:Cursor-blinkon0
        set guicursor+=i:ver25-iCursor-blinkwait20
endif

set ls=2                            " allways show status line
set number                          " show line numbers
set nowrap                          " Don't wrap lines
set ruler                           " show line and column
set showmatch                       " show matching braces

" Tab and indent options  =======================================================
set tabstop=4                       " Tab is 4 spaces and NOT the default 8
set shiftwidth=4                    " numbers of spaces to (auto)indent
set expandtab                       " Expand tab to spaces
set cindent                         " cindent
set smartindent                     " smart indent
set autoindent                      " always set autoindenting on
set softtabstop=4                   " makes the spaces feel like real tabs. E.g. back deletes all 4 chars
set backspace=indent,eol,start      " backspace deletes indent, eol and start line

" Search options  ===============================================================
set ignorecase                      " Ignore spaces in seach (I use Windows!!!!)
set incsearch                       " do incremental searching
set hlsearch                        " highlight searches

" File options  =================================================================
set nobackup                        " do not keep a backup file. I hate '~' in file names
map <C-s> :w <cr>
nmap <F11> :silent !start explorer /select,%:p <cr> " open and select in explorer

"Razzle build commands ==========================================================
autocmd BufEnter * lcd %:p:h        " on file open cd to it's folder
map <f6>  :!build %:p:h <cr>        " F6 builds
map <C-f6>  :!build -c %:p:h <cr>   " Ctrl+F6 clean builds
map <c-t> :silent !tf edit % <cr>   " Ctrl+t checks out file (tf -edit)
map <c-d> :silent !tf diff % <cr>   " ctrl+d does a tf -diff of the current file
