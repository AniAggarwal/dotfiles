local status_ok, tree = pcall(require, "nvim-tree")
if not status_ok then
	return
end

tree.setup({

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
