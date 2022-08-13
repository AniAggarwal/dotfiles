" Python specific config for Neovim. Plugin specific configurations for python
" are stored in their respective files.

" Make NeoVim use nvim conda env
let g:python3_host_prog='/home/ani/miniconda3/envs/nvim/bin/python'

" run black manually by typing :black
command Black :!black %
