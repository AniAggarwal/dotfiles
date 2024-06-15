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
-- keymap("n", "<C-h>", "<C-w>h", opts)
-- keymap("n", "<C-j>", "<C-w>j", opts)
-- keymap("n", "<C-k>", "<C-w>k", opts)
-- keymap("n", "<C-l>", "<C-w>l", opts)

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

-- Check if the environment variable is set to not start Copilot
-- if os.getenv("NVIM_DISABLE_COPILOT") then
-- 	-- Define an autocmd to run DisableCopilot when a buffer is opened
-- 	vim.cmd([[
--     augroup DisableCopilotOnBufferOpen
--         autocmd!
--         autocmd BufEnter * lua DisableCopilot()
--     augroup END
--     ]])
-- end


if os.getenv("NVIM_DISABLE_COPILOT") then
  -- Define a function to disable Copilot after a delay
  function DelayedDisableCopilot()
    vim.defer_fn(function()
      DisableCopilot()
    end, 3000)
  end

  -- Define an autocmd to run DelayedDisableCopilot when a buffer is opened
  vim.cmd([[
    augroup DisableCopilotOnBufferOpen
      autocmd!
      autocmd BufEnter * lua DelayedDisableCopilot()
    augroup END
  ]])
end
