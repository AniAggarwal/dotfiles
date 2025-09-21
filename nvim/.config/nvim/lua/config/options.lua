-- Backup and File Management
vim.opt.backup = false            -- No backup file
vim.opt.swapfile = false          -- No swap file
vim.opt.undofile = true           -- Enable persistent undo
vim.opt.writebackup = false       -- No write backup file
vim.opt.fileencoding = "utf-8"    -- Use UTF-8 encoding for files

-- Clipboard and Mouse
vim.opt.clipboard = "unnamedplus" -- Access system clipboard
vim.opt.mouse = "a"               -- Enable mouse support

-- Interface Options
vim.opt.termguicolors = true      -- Enable terminal GUI colors
vim.opt.cmdheight = 1             -- More space in the command line
vim.opt.showmode = false          -- Hide mode messages (e.g. -- INSERT --)
vim.opt.showtabline = 2           -- Always show the tab line
vim.opt.laststatus = 3            -- Global statusline
vim.opt.number = true             -- Show line numbers
vim.opt.cursorline = true         -- Highlight the current line
vim.opt.signcolumn = "yes"        -- Always show the sign column
vim.opt.fillchars.eob = " "       -- Fill empty buffer with spaces

vim.opt.winborder = "rounded"

-- Search and Display Options
vim.opt.hlsearch = true           -- Highlight search results
vim.opt.ignorecase = true         -- Ignore case when searching
vim.opt.smartcase = true          -- Override ignorecase if pattern contains uppercase

-- Completion Menu
vim.opt.completeopt = { "menuone", "noselect" } -- Better completion experience

-- Popup Menu
vim.opt.pumheight = 10            -- Popup menu height

-- Splitting Windows
vim.opt.splitbelow = true         -- Horizontal splits below current window
vim.opt.splitright = true         -- Vertical splits to the right of current window

-- Performance and Timings
vim.opt.timeoutlen = 400          -- Time to wait for a mapped sequence (in ms)
vim.opt.updatetime = 300          -- Faster completion (default is 4000ms)

-- Tabs & Indentation
vim.opt.smartindent = true        -- Smart indentation
vim.opt.expandtab = true          -- Convert tabs to spaces
vim.opt.shiftwidth = 4            -- Number of spaces per indentation
vim.opt.tabstop = 4               -- Insert 4 spaces for a tab

-- -- Folding (Treesitter)
-- vim.opt.foldmethod = "expr"       -- Use Treesitter for folding
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
-- vim.opt.foldenable = false        -- Disable folding by default

-- Folding (UFO)
vim.opt.foldenable = true
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99


-- Text Wrapping and Line Breaks
vim.opt.wrap = false              -- Don't wrap lines
vim.opt.scrolloff = 2             -- Keep 2 lines of context around the cursor
vim.opt.sidescrolloff = 2         -- Keep 2 columns of context around the cursor

-- Message and Display Configuration
vim.opt.shortmess:append("c")     -- Shorten messages (e.g., completion messages)
vim.opt.whichwrap:append("<,>,[,],h,l") -- Allow movement across wrapped lines
vim.opt.spelloptions:append({ "camel" }) -- Handle camel case in spell check

-- Set python interpreter for Neovim
vim.g.python3_host_prog = os.getenv("HOME") .. "/micromamba/envs/nvim/bin/python"


-- Set copilot model
vim.g.copilot_settings = { selectedCompletionModel = 'calude-4' }
