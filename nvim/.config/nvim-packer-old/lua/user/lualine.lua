require("lualine").setup({
	options = {
		theme = "onedark",
		globalstatus = true,
		disabled_filetypes = {
			"alpha",
		},
	},
	sections = {
		lualine_x = { "encoding", "filetype", "' ' .. os.getenv('CONDA_DEFAULT_ENV')" },
	},
})
