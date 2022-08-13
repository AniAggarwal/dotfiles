" Settings for vim sneak

" label other matches when searching
let g:sneak#label = 1

" case insensitive sneak
let g:sneak#use_ic_scs = 1

" immediately move to the next instance of search
let g:sneak#s_next = 1

" Use , and ; with f and t
map gS <Plug>Sneak_,
map gs <Plug>Sneak_;
