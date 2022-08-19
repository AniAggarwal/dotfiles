" Key remappings for Neovim and plugins

" Don't wait as long for keybinds
set timeoutlen=750
" Remap escape to the seqeunce jk
inoremap jk <Esc>
" Remap delete to ctrl+d in insert mode
inoremap <C-d> <Del>
" Remap ctrl+h to delete next word in insert mode
inoremap <C-h> <C-o>dw
" Remap enter normal mode in terminal to ctrl+n
tnoremap <C-n> <C-\><C-n>
" Remap leader key to space
let mapleader = "\<Space>"
" Turn off highlighting faster
noremap <leader>h :noh<CR>
" Toggle spell checking
nnoremap z- :set spell!<CR>
" Save files faster
nnoremap <leader>w :w<CR>

" Mappings for Fugitive
nmap <leader>gs :G<CR>
nmap <leader>gh :diffget //3<CR>
nmap <leader>gl :diffget //2<CR>

" Use alt + hjkl to resize windows
nnoremap <M-j> :resize -2<CR>
nnoremap <M-k> :resize +2<CR>
nnoremap <M-h> :vertical resize -2<CR>
nnoremap <M-l> :vertical resize +2<CR>

" Better window and buffer navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <tab> :bn<CR>
nnoremap <S-tab> :bp<CR>
" Better window navigation in terminal too
tnoremap <C-h> <C-\><C-n><C-w>h
tnoremap <C-j> <C-\><C-n><C-w>j
tnoremap <C-k> <C-\><C-n><C-w>k
tnoremap <C-l> <C-\><C-n><C-w>l

" Open NERDTree focus with ctrl+t
nnoremap <C-t> :NERDTreeFocus<CR>
" Use s (like sp) and v (like vs) for splitting
let NERDTreeMapOpenSplit='s'
let NERDTreeMapOpenVSplit='v'

" Open code outline using CocOutline
nnoremap <F8> :CocOutline<CR>

" Comment current line out and paste it below
nnoremap gcp yy <bar> :Commentary<CR> <bar> p

" Mapping for activating conda env
nnoremap <leader>tc :call CopyCondaEnvName()<CR>"cp A<CR>
" Open new terminal, move cursor to it, and activate conda env
nmap <leader>tn :Tnew <bar> :wincmd w<CR><leader>tc
" Clear given terminal
nnoremap <leader>tl :<c-u>exec v:count.'Tclear'<CR>
" Toggle given terminal and move cursor to it
nmap <leader>tt :Ttoggle <bar> :wincmd w<CR><leader>tc
" Run current file as python file
nmap <leader>trp <leader>tt<C-n><C-w>W :T python %<CR>

function CopyCondaEnvName()
    let @c = "conda activate ". $CONDA_DEFAULT_ENV
endfunction


" Remap execution of jupyter notebook cells in nvim
nmap <leader>jx <Plug>JupyterExecute
nmap <leader>jX <Plug>JupyterExecuteAll
" Create new code cell
nnoremap <leader>jc o# %%<CR>


" Use ctrl-s to split instead of default ctrl-x in FZF
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }

" Search files using FZF
nnoremap <Leader>F :Files<CR>
" Search using rg
nnoremap <Leader>R :Rg<CR>
" Search all lines in current buffer
nnoremap <Leader>L :BLines<CR>
" Search open buffers
nnoremap <Leader>B :Buffers<CR>
" Search current buffer's tags
nnoremap <Leader>Tb :BTags<CR>
" Search using Vista
nnoremap <Leader>Tv :Vista finder<CR>
" Search all commands
nnoremap <C-Space> :Commands<CR>
" File explorer via ranger
nnoremap <M-t> :RnvimrToggle<CR>

" Mappings to use FZF for Coc searches
nnoremap <silent> <Leader><space> :<C-u>CocFzfList<CR>
nnoremap <silent> <Leader>b       :<C-u>CocFzfList diagnostics --current-buf<CR>
nnoremap <silent> <Leader>c       :<C-u>CocFzfList commands<CR>
nnoremap <silent> <Leader>e       :<C-u>CocFzfList extensions<CR>
nnoremap <silent> <Leader>l       :<C-u>CocFzfList location<CR>
nnoremap <silent> <Leader>o       :<C-u>CocFzfList outline<CR>
nnoremap <silent> <Leader>s       :<C-u>CocFzfList symbols<CR>
nnoremap <silent> <Leader>p       :<C-u>CocFzfListResume<CR>

" Access tabs using leader and tab number
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
nmap <leader>+ <Plug>AirlineSelectNextTab

" Use ctrl+n to accept copilot completions
inoremap <silent><script><expr> <C-n> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true

" coc snippets
" Use <C-l> for trigger snippet expand.
imap <C-l> <Plug>(coc-snippets-expand)
" Use <C-j> for select text for visual placeholder of snippet.
vmap <C-j> <Plug>(coc-snippets-select)
" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-j>'
" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-k>'
" Use <C-j> for both expand and jump (make expand higher priority.)
imap <C-j> <Plug>(coc-snippets-expand-jump)
