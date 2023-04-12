require("nvim-tree").setup({
	disable_netrw = true,

	diagnostics = {
		enable = true,
	},

	view = {
		mappings = {
			list = {
				{ key = "<C-s>", action = "split" },
				{ key = "<C-x>", action = "" },
			},
		},
	},

	-- for syncing with project_nvim
	sync_root_with_cwd = true,
	respect_buf_cwd = true,
	update_focused_file = {
		enable = true,
		update_root = true,
	},
})

local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- create a new, empty buffer
	vim.cmd.enew()

	-- wipe the directory buffer
	vim.cmd.bw(data.buf)

	-- change to the directory
	vim.cmd.cd(data.file)

	-- open the tree
	require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
