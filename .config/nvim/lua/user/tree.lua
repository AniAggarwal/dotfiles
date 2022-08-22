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
			},
		},
	},
})
