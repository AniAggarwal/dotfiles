-- more info via :help options
vim.opt.backup = false -- creates a backup file
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.cmdheight = 1 -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0 -- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8" -- the encoding written to a file
vim.opt.hlsearch = true -- highlight all matches on previous search pattern
vim.opt.ignorecase = true -- ignore case in search patterns
vim.opt.mouse = "a" -- allow the mouse to be used in neovim
vim.opt.pumheight = 10 -- pop up menu height
vim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 2 -- always show tabs
vim.opt.smartcase = true -- smart case
vim.opt.smartindent = true -- make indenting smarter again
vim.opt.splitbelow = true -- force all horizontal splits to go below current window
vim.opt.splitright = true -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false -- creates a swapfile
vim.opt.termguicolors = true -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 400 -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true -- enable persistent undo
vim.opt.updatetime = 300 -- faster completion (4000ms default)
vim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.shiftwidth = 4 -- the number of spaces inserted for each indentation
vim.opt.tabstop = 4 -- insert 2 spaces for a tab
vim.opt.cursorline = true -- highlight the current line
vim.opt.number = true -- set numbered lines
vim.opt.laststatus = 3 -- include a status line all the time on the last window
vim.opt.showcmd = false --
vim.opt.ruler = false
vim.opt.numberwidth = 4 -- set number column width to 2 {default 4}
vim.opt.signcolumn = "yes" -- always show the sign column, otherwise it would shift the text each time
vim.opt.scrolloff = 2 -- how many lines of context to show around current line
vim.opt.sidescrolloff = 2
vim.opt.guifont = "FiraCode Nerd Font:h17" -- the font used in graphical neovim applications
vim.opt.fillchars.eob = " " -- the char to fill the end of a buffer with
vim.opt.shortmess:append("c") -- don't give |ins-completion-menu| messages, for example, "match 1 of 2".
vim.opt.whichwrap:append("<,>,[,],h,l")
vim.g.python3_host_prog = "/home/ani/micromamba/envs/nvim/bin/python" -- Use nvim conda env
vim.opt.foldmethod = "expr" -- Use nvim-treesitter for folding
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false -- leave file unfolded by default
vim.opt.wrap = false -- display lines as one long line
-- vim.opt.textwidth = 79 -- max line length
vim.opt.spelloptions:append({ "camel" }) -- allow camel case words to be detected correctly for spell check

-- soft wrap text files
vim.api.nvim_create_autocmd(
	"FileType",
	{ pattern = "text", command = "setlocal wrap | setlocal tw=0 | setlocal linebreak | setlocal spell" }
)
-- remap gj, gk to j, k, for wrapped line navigation
vim.keymap.set({ "n", "x" }, "j", "gj", { noremap = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "gk", { noremap = true, silent = true })

-- hard wrap text files
-- vim.api.nvim_create_autocmd(
-- 	"FileType",
-- 	{ pattern = "text", command = "setlocal wrap | setlocal tw=80 | setlocal linebreak | setlocal spell" }
-- )

vim.api.nvim_create_autocmd("FileType", { pattern = "Outline", command = "setlocal nospell" }) -- No spelling on symbols outline
vim.api.nvim_create_autocmd(
	"FileType",
	{ pattern = "asm", command = "setlocal noexpandtab | setlocal tabstop=8 | setlocal shiftwidth=8" }
)
