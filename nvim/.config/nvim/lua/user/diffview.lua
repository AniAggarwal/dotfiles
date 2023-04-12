local actions = require("diffview.actions")

require("diffview").setup({
	enhanced_diff_hl = true,
	file_panel = {
		win_config = {
			type = "split",
			position = "bottom",
			height = 10,
		},
	},

	keymaps = {
		disable_defaults = false, -- Disable the default keymaps
		diff3 = {
			-- Mappings in 3-way diff layouts
			{
				{ "n", "x" },
				"<leader>go",
				actions.diffget("ours"),
				{ desc = "Obtain the diff hunk from the OURS version of the file" },
			},
			{
				{ "n", "x" },
				"<leader>gt",
				actions.diffget("theirs"),
				{ desc = "Obtain the diff hunk from the THEIRS version of the file" },
			},
			{ "n", "g?", actions.help({ "view", "diff3" }), { desc = "Open the help panel" } },
		},
		diff4 = {
			-- Mappings in 4-way diff layouts
			{
				{ "n", "x" },
				"<leader>gb",
				actions.diffget("base"),
				{ desc = "Obtain the diff hunk from the BASE version of the file" },
			},
			{
				{ "n", "x" },
				"<leader>go",
				actions.diffget("ours"),
				{ desc = "Obtain the diff hunk from the OURS version of the file" },
			},
			{
				{ "n", "x" },
				"<leader>gt",
				actions.diffget("theirs"),
				{ desc = "Obtain the diff hunk from the THEIRS version of the file" },
			},
			{ "n", "g?", actions.help({ "view", "diff4" }), { desc = "Open the help panel" } },
		},
	},
})
