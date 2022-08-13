" Config for vista symbols and tags in sidebar

" Enable rendering of icons in sidebar
let g:vista#renderer#enable_icon = 1
let g:vista#renderer#enable_tag = 1

" Open taking up more space
let g:vista_sidebar_width = 35
" Use coc instead of ctags to generate tags
let g:vista_default_executive = "coc"
" Show info when hovering over tags in a floating window
let g:vista_echo_cursor_strategy = "floating_win"
" Only display more info when pressing p
let g:vista_echo_cursor = 0
" Update tags when they are modified in the file instead of waiting for saving
let g:vista_update_on_text_changed = 1

" TODO: make line highlight when using vista finder (--highlight-line option
" for bat may help here, passed to fzf#run())
let g:vista_fzf_preview = ['right:50%']


" This stuff doens't work. Leave for later if I decide to revist
" let g:vista_disable_statusline = 1
" function! NearestMethodOrFunction() abort
"   return get(b:, 'vista_nearest_method_or_function', '')
" endfunction

" let g:airline#extensions#default#layout = [['a', 'b', 'c'], ['x', 'y', 'z', 'warning', 'error']]

" call airline#parts#define_function('nearest_method', 'NearestMethodOrFunction')
" let g:airline_section_x = airline#section#create([' ','nearest_method', '() | ', 'filetype'])
" autocmd VimEnter * call vista#RunForNearestMethodOrFunction()
" autocmd BufEnter *.py :Vista<CR>
" augroup testgroup : autocmd! : autocmd BufEnter *.py :Vista<CR> augroup END
