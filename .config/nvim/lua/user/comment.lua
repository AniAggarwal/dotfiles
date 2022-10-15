require("Comment").setup({})

local U = require("Comment.utils")
local A = require("Comment.api")

function _G.___gdc(motion)
	local range = U.get_region(motion)
	local lines = U.get_lines(range)

	-- Copying the block
	local srow = range.erow
	vim.api.nvim_buf_set_lines(0, srow, srow, false, lines)

	-- Doing the comment
	A.comment.linewise(motion)

	-- Move the cursor
	local erow = srow + 1
	local line = U.get_lines({ srow = srow, erow = erow })
	local col = U.indent_len(line[1])
	vim.api.nvim_win_set_cursor(0, { erow, col })
end

-- TODO: make this work, either here or in whichkey
-- vim.api.nvim_set_keymap("x", "gy", "<ESC><CMD>lua ___gdc(vim.fn.visualmode())<CR>", { silent = true, noremap = true })
-- vim.api.nvim_set_keymap("n", "gy", "<CMD>set operatorfunc=v:lua.___gdc<CR>g@", { silent = true, noremap = true })

