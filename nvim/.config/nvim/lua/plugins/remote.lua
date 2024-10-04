return {
	{
		"chipsenkbeil/distant.nvim",
		branch = "v0.3",
		config = function()
			require("distant"):setup()
		end,
	},

	{
		"KenN7/vim-arsync",
		dependencies = { "prabirshrestha/async.vim" },
		cmd = { "ARshowConf", "ARsyncDown", "ARsyncUp", "ARsyncUpDelete" },
		keys = {
			{ "<leader>au", "<cmd>ARsyncUp<CR>", desc = "Rsync Up to Remote" },
			{ "<leader>ad", "<cmd>ARsyncDown<CR>", desc = "Rsync Down from Remote" },
		},
	},
	{
		"amitds1997/remote-nvim.nvim",
		version = "*", -- Pin to GitHub releases
		dependencies = {
			"nvim-lua/plenary.nvim", -- For standard functions
			"MunifTanjim/nui.nvim", -- To build the plugin UI
			"nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
		},
		config = true,
		opts = {
			-- offline_mode = {
			--     enabled = true,
			--     no_github = true,
			--     -- cache_dir = vim.fn.stdpath(".local") .. "/bin"
			-- }
		},
	},
}
