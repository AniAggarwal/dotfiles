" Config for indent blankline using vim
" -- Config for indent blankline using lua


let g:indent_blankline_filetype_exclude = ['lspinfo', 'packer', 'checkhealth', 'help', 'startify', 'terminal', 'neoterm'] 
" Don't have indent lines on completly blank lines
let g:indent_blankline_show_trailing_blankline_indent = v:false


lua << EOF
require("indent_blankline").setup {
    -- Highlights current scope indentation line
    show_current_context = true,
}
EOF
