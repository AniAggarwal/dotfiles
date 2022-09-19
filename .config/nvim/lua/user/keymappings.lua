-- Shorten function name
local keymap = vim.keymap.set
-- Silent keymap option
local opts = { silent = true }

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
keymap("n", "<C-Up>", "<cmd>resize -2<CR>", opts)
keymap("n", "<C-Down>", "<cmd>resize +2<CR>", opts)
keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", opts)
keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", opts)

-- Close buffers
keymap("n", "<S-q>", "<cmd>Bdelete<CR>", opts)

-- Better paste - pasting on highlighted texts keeps originally yanked text
keymap("v", "p", '"_dP', opts)


-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)

-- Use ctrl+d to delete backwards
keymap("i", "<C-d>", "<Del>", opts)

-- Use ctrl+h to delete next word
keymap("i", "<C-h>", "<C-o>dw", opts)

-- Toggle spell checking
keymap("n", "z-", "<cmd>set spell!<CR>", opts)


-- Visual --
-- Stay in indent mode after indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up/down
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "<A-j>", ":m .+1<CR>==", opts)

-- Visual Block --
-- Move text up/down
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)


-- Command Mode --
-- Use ctrl+h/j/k/l to move cursor
-- TODO make this work
keymap("c", "<C-h>", "<Left>", opts)
keymap("c", "<C-j>", "<Down>", opts)
keymap("c", "<C-k>", "<Up>", opts)
keymap("c", "<C-l>", "<Right>", opts)

-- Plugins --

-- LSP
vim.keymap.set("n", "]g", vim.diagnostic.goto_next, { noremap = true, silent = true })
vim.keymap.set("n", "[g", vim.diagnostic.goto_prev, { noremap = true, silent = true })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true })

-- Todo Comments
vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { noremap = true, silent = true })

vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { noremap = true, silent = true  })

-- Comment
-- TODO: make this work
-- keymap("n", "gcp", "yy <bar> gcc <bar> p", opts)
-- TODO: look into using Telescope for marks and jumplist

-- Trouble
keymap("n", "gr", "<cmd>TroubleToggle lsp_references<CR>", opts)
keymap("n", "gL", "<cmd>TroubleToggle document_diagnostics<CR>", opts)

-- Git
keymap("n", "]c", "<cmd>Gitsigns next_hunk<CR>", opts)
keymap("n", "[c", "<cmd>Gitsigns prev_hunk<CR>", opts)

-- Bufferline
keymap("n", "<S-M-l>", ":BufferLineMoveNext<CR>", opts)
keymap("n", "<S-M-h>", ":BufferLineMovePrev<CR>", opts)

-- Dressing
vim.keymap.set("n", "z=", function()
  local word = vim.fn.expand("<cword>")
  local suggestions = vim.fn.spellsuggest(word)
  vim.ui.select(
    suggestions,
    {},
    vim.schedule_wrap(function(selected)
      if selected then
        vim.api.nvim_feedkeys("ciw" .. selected, "n", true)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)
      end
    end)
  )
end)

-- -- DAP
-- keymap("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", opts)
-- keymap("n", "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", opts)
-- keymap("n", "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", opts)
-- keymap("n", "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", opts)
-- keymap("n", "<leader>dO", "<cmd>lua require'dap'.step_out()<cr>", opts)
-- keymap("n", "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>", opts)
-- keymap("n", "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>", opts)
-- keymap("n", "<leader>du", "<cmd>lua require'dapui'.toggle()<cr>", opts)
-- keymap("n", "<leader>dt", "<cmd>lua require'dap'.terminate()<cr>", opts)
