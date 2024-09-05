-- Shorten function name
local keymap = vim.keymap.set
local opts = { silent = true }

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- Better paste - pasting on highlighted text keeps the original yanked text
keymap("v", "p", '"_dP', opts)

-- Insert mode keymaps --
-- Press jk fast to enter Normal mode
keymap("i", "jk", "<ESC>", opts)

-- Use ctrl+d to delete forward
keymap("i", "<C-d>", "<Del>", opts)

-- Use ctrl+h to delete the next word
keymap("i", "<C-h>", "<C-o>dw", opts)

-- Toggle spell checking
keymap("n", "z-", "<cmd>set spell!<CR>", opts)

-- Visual mode keymaps --
-- Stay in indent mode after indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up/down
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "<A-j>", ":m .+1<CR>==", opts)

-- Visual Block mode keymaps --
-- Move text up/down
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Command mode keymaps --
-- Use ctrl+h/j/k/l to move the cursor
keymap("c", "<C-h>", "<Left>", {})
keymap("c", "<C-j>", "<Down>", {})
keymap("c", "<C-k>", "<Up>", {})
keymap("c", "<C-l>", "<Right>", {})

-- Terminal mode keymaps --
keymap("t", "<C-\\>", "<C-\\><C-n>", opts)


