" Config for startify

" Keep session files in session config folder
let g:startify_session_dir = '~/.config/nvim/session'

let g:startify_session_delete_buffers = 1
let g:startify_change_to_vcs_root = 1
let g:startify_session_persistence = 1
let g:startify_enable_special = 0

" Enable cursorline in Startify
autocmd User Startified setlocal cursorline

" Keeps NERDTree from causing issues when SSave is called with it open
" This is because NERDTree becomes a blank buffer when loaded from session
set sessionoptions-=blank

" let g:startify_lists = [
"             \ { 'type': 'sessions',  'header': startify#center(['Sessions'])},
"           \ { 'type': 'bookmarks', 'header': startify#center(['Bookmarks'])},
"           \ { 'type': 'files',     'header': startify#center(['Files'])},
"           \ { 'type': 'dir',       'header': startify#center(['Current Directory '. getcwd()])},
"           \ ]
let g:startify_lists = [
          \ { 'type': 'sessions',  'header': ['   Sessions']},
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']},
          \ { 'type': 'files',     'header': ['   Files']},
          \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()]},
          \ ]

let g:startify_bookmarks = [
            \ { 'd': '~/dev/' },
            \ { 'p': '~/dev/projects' },
            \ '~/Downloads',
            \ ]

" Padding for lists
" let g:startify_padding_left = $COLUMNS / 2
" let g:startify_padding_left = 50

" let g:startify_custom_header = startify#center(readfile('/home/ani/Downloads/ascii-good/goku-smile-clean-80.txt'))
let current_path = '/home/ani/.config/nvim/headers/goku-smile-90.txt'
let g:startify_custom_header = readfile(current_path)
" let g:startify_custom_header = readfile('/home/ani/Downloads/ascii-good/goku-cloud-minimal-80.txt')
" let g:startify_custom_header = readfile('/home/ani/Downloads/ascii-good/goku-jump-clean-80.txt')

" " TODO get better header
" let s:startify_ascii_header = [
"  \ '                                        ▟▙            ',
"  \ '                                        ▝▘            ',
"  \ '██▃▅▇█▆▖  ▗▟████▙▖   ▄████▄   ██▄  ▄██  ██  ▗▟█▆▄▄▆█▙▖',
"  \ '██▛▔ ▝██  ██▄▄▄▄██  ██▛▔▔▜██  ▝██  ██▘  ██  ██▛▜██▛▜██',
"  \ '██    ██  ██▀▀▀▀▀▘  ██▖  ▗██   ▜█▙▟█▛   ██  ██  ██  ██',
"  \ '██    ██  ▜█▙▄▄▄▟▊  ▀██▙▟██▀   ▝████▘   ██  ██  ██  ██',
"  \ '▀▀    ▀▀   ▝▀▀▀▀▀     ▀▀▀▀       ▀▀     ▀▀  ▀▀  ▀▀  ▀▀',
"  \ '',
"  \]

" let s:startify_ascii_header = [
"  \ '                                         __               ',
"  \ '                                        |  \              ',
"  \ ' _______    ______    ______  __     __  \$$ ______ ____  ',
"  \ '|       \  /      \  /      \|  \   /  \|  \|      \    \ ',
"  \ '| $$$$$$$\|  $$$$$$\|  $$$$$$\\$$\ /  $$| $$| $$$$$$\$$$$\',
"  \ '| $$  | $$| $$    $$| $$  | $$ \$$\  $$ | $$| $$ | $$ | $$',
"  \ '| $$  | $$| $$$$$$$$| $$__/ $$  \$$ $$  | $$| $$ | $$ | $$',
"  \ '| $$  | $$ \$$     \ \$$    $$   \$$$   | $$| $$ | $$ | $$',
"  \ ' \$$   \$$  \$$$$$$$  \$$$$$$     \$     \$$ \$$  \$$  \$$',
"  \]


" let s:startify_ascii_header = [
"  \ '                                        $$\                ',
"  \ '                                        \__|               ',
"  \ '$$$$$$$\   $$$$$$\   $$$$$$\ $$\    $$\ $$\ $$$$$$\$$$$\   ',
"  \ '$$  __$$\ $$  __$$\ $$  __$$\\$$\  $$  |$$ |$$  _$$  _$$\  ',
"  \ '$$ |  $$ |$$$$$$$$ |$$ /  $$ |\$$\$$  / $$ |$$ / $$ / $$ | ',
"  \ '$$ |  $$ |$$   ____|$$ |  $$ | \$$$  /  $$ |$$ | $$ | $$ | ',
"  \ '$$ |  $$ |\$$$$$$$\ \$$$$$$  |  \$  /   $$ |$$ | $$ | $$ | ',
"  \ '\__|  \__| \_______| \______/    \_/    \__|\__| \__| \__| ',
"  \]

" let s:startify_ascii_header = [
"  \ '███╗░░██╗███████╗░█████╗░██╗░░░██╗██╗███╗░░░███╗',
"  \ '████╗░██║██╔════╝██╔══██╗██║░░░██║██║████╗░████║',
"  \ '██╔██╗██║█████╗░░██║░░██║╚██╗░██╔╝██║██╔████╔██║',
"  \ '██║╚████║██╔══╝░░██║░░██║░╚████╔╝░██║██║╚██╔╝██║',
"  \ '██║░╚███║███████╗╚█████╔╝░░╚██╔╝░░██║██║░╚═╝░██║',
"  \ '╚═╝░░╚══╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝',
"  \]

" let g:startify_ascii_header = [
"                 \ "      .            .      ",
"                 \ "    .,;'           :,.    ",
"                 \ "  .,;;;,,.         ccc;.  ",
"                 \ ".;c::::,,,'        ccccc: ",
"                 \ ".::cc::,,,,,.      cccccc.",
"                 \ ".cccccc;;;;;;'     llllll.",
"                 \ ".cccccc.,;;;;;;.   llllll.",
"                 \ ".cccccc  ';;;;;;'  oooooo.",
"                 \ "'lllllc   .;;;;;;;.oooooo'",
"                 \ "'lllllc     ,::::::looooo'",
"                 \ "'llllll      .:::::lloddd'",
"                 \ ".looool       .;::coooodo.",
"                 \ "  .cool         'ccoooc.  ",
"                 \ "    .co          .:o:.    ",
"                 \ "      .           .'      ",
"                 \]

" let g:startify_custom_header = 'startify#center(g:startify_ascii_header)'


" redir => test
"   silent echo 'one'
"   silent echo 'two'
"   silent echo 'three'
" redir END
" redir => custom_header
"     execute('cat /home/ani/Downloads/ascii-good/goku-smile-clean-80.txt')
" redir END


" let g:startify_custom_header = split(custom_header)
" let g:startify_custom_header = startify#center(split(custom_header))
" let g:startify_custom_header = map(split(test), 'repeat(" ", 10) . v:val')
