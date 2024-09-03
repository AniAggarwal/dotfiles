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

-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
vim.keymap.set("n", "<A-H>", require("smart-splits").resize_left)
vim.keymap.set("n", "<A-J>", require("smart-splits").resize_down)
vim.keymap.set("n", "<A-K>", require("smart-splits").resize_up)
vim.keymap.set("n", "<A-L>", require("smart-splits").resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right)

-- Navigate buffers
keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", opts)
keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", opts)

keymap("n", "<C-M-l>", ":BufferLineMoveNext<CR>", opts)
keymap("n", "<C-M-h>", ":BufferLineMovePrev<CR>", opts)

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
keymap("c", "<C-h>", "<Left>", {})
keymap("c", "<C-j>", "<Down>", {})
keymap("c", "<C-k>", "<Up>", {})
keymap("c", "<C-l>", "<Right>", {})

-- Terminal Mode
keymap("t", "<C-\\>", "<C-\\><C-n>", opts)

-- Plugins --

-- LSP
vim.keymap.set("n", "]g", vim.diagnostic.goto_next, { noremap = true, silent = true })
vim.keymap.set("n", "[g", vim.diagnostic.goto_prev, { noremap = true, silent = true })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true })

-- DAP

keymap("n", "<F5>", "<cmd>lua require'dap'.continue()<CR>", opts)
keymap("n", "<F6>", "<cmd>lua require'dap'.step_into()<CR>", opts)
keymap("n", "<F7>", "<cmd>lua require'dap'.step_over()<CR>", opts)
keymap("n", "<F8>", "<cmd>lua require'dap'.step_out()<CR>", opts)

vim.cmd("command! JdtDebugJUnitMethod lua require'jdtls'.test_nearest_method()")
vim.cmd("command! JdtDebugJUnitClass lua require'jdtls'.test_class()")

-- Todo Comments
vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next()
end, { noremap = true, silent = true })

vim.keymap.set("n", "[t", function()
	require("todo-comments").jump_prev()
end, { noremap = true, silent = true })

-- Comment and copy
vim.keymap.set("n", "gcp", "yy<Plug>(comment_toggle_linewise_current)p")
vim.keymap.set("x", "gp", "ygv<Plug>(comment_toggle_linewise_visual)`>p")

-- Trouble
keymap("n", "gr", "<cmd>TroubleToggle lsp_references<CR>", opts)
keymap("n", "gL", "<cmd>TroubleToggle document_diagnostics<CR>", opts)

-- Git
keymap("n", "]c", "<cmd>Gitsigns next_hunk<CR>", opts)
keymap("n", "[c", "<cmd>Gitsigns prev_hunk<CR>", opts)

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

function DisableCopilot()
	local target_name = "copilot"
	local clients = vim.lsp.get_clients()

	for _, client in ipairs(clients) do
		if client.name == target_name then
			vim.lsp.stop_client(client.id)
			print("Copilot client detached.")
			return
		end
	end

	print("Copilot client not found.")
end

vim.cmd("command! DisableCopilot lua DisableCopilot()")

if os.getenv("NVIM_DISABLE_COPILOT") then
	-- Define a function to disable Copilot after a delay
	-- function DelayedDisableCopilot()
	-- 	vim.defer_fn(function()
	-- 		DisableCopilot()
	-- 	end, 3000)
	-- end

	-- Define an autocmd to run DelayedDisableCopilot when a buffer is opened
	vim.cmd([[
    augroup DisableCopilotOnBufferOpen
      autocmd!
      autocmd BufEnter * lua DelayedDisableCopilot()
    augroup END
  ]])
end
