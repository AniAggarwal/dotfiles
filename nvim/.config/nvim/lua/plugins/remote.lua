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
            {"<leader>au", "<cmd>ARsyncUp<CR>", desc = "Rsync Up to Remote" },
            {"<leader>ad", "<cmd>ARsyncDown<CR>", desc = "Rsync Down from Remote" },
        }
	},
}
