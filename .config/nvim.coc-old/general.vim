" General Config for Neovim

" Indention
set autoindent
" Use instead of outdated smartindent
filetype plugin indent on
" Recommended to use 7 by vim
set tabstop=8
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab

" Split to the right and below by default
set splitbelow
set splitright

" Use filetype plugins
filetype plugin on

" Show signs next to lines
set signcolumn=yes
" Add line numbers
set number
" Enable mouse support
set mouse=a
" Use default system clipboard
set clipboard+=unnamedplus
" Set English as language for spell checking
set spelllang=en
" Show only best 10 spelling suggestions
set spellsuggest=best,10
" Enable syntax highlighting
syntax enable
" Required to allow multiple buffers open
set hidden
" Bottom line with info
set ruler
" Show current line with slight highlighting
set cursorline
" Don't wrap long lines
set nowrap
" Always show status bar
set laststatus=2
" Always show tabline
set showtabline=2
" Don't use old Vi stuff
set nocompatible
