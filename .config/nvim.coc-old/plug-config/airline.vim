" Config for airline extension

" Enable top tabline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_idx_mode = 1

" Enable fugitive support
let g:airline#extensions#fugitiveline#enabled = 1

" Enable powerline fonts
let g:airline_powerline_fonts = 1

" Disable here so that vista can add without double additions
let g:airline#extensions#tagbar#enabled = 0

" let g:airline_left_sep = ''
" let g:airline_right_sep = ''
" let g:airline#extensions#tabline#left_sep = ''
" let g:airline#extensions#tabline#left_alt_sep = ''
" let g:airline#extensions#tabline#right_sep = ''
" let g:airline#extensions#tabline#right_alt_sep = ''

" TODO: for later, clock in statusline
" let g:airline_section_y = '%{strftime("%H:%M")}'
" let g:airline_section_y = airline#section#create(['%{strftime("%H:%M")}', 'fileformat', 'bom', 'eol'])
" let g:airline_section_y = airline#section#create(['%{strftime("%H:%M")}', g:airline_section_y])
" let g:airline#extensions#clock#auto = 0
" function! AirlineInit()
"   let g:airline_section_y = airline#section#create(['clock', g:airline_symbols.space, g:airline_section_y])
" endfunction
" autocmd User AirlineAfterInit call AirlineInit()
" let g:airline_section_y = '%{strftime("%H:%M")}'

" Switching to current theme
let g:airline_theme = 'onedark'

" Always show tabs
set showtabline=2

" Don't want -- INSERT -- to display
set noshowmode


" Display conda env in status line
function! GetCondaEnv() abort
    if $CONDA_DEFAULT_ENV == ''
        return 'NONE'
    else
        return $CONDA_DEFAULT_ENV
    endif
endfunction

call airline#parts#define_function('get_conda_env', 'GetCondaEnv')
let g:airline_section_x = airline#section#create(['filetype', ' (', 'get_conda_env', ')'])


