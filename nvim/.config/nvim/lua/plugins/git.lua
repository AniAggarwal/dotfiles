return {

	{
		"kdheepak/lazygit.nvim",
		cmd = "LazyGit",
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<CR>", desc = "Open LazyGit" },
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "󰐊" },
				topdelete = { text = "󰐊" },
				changedelete = { text = "▎" },
			},
			preview_config = {
				border = "rounded",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		},
		keys = {
			{ "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage hunk" },
			{ "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset hunk" },
			{ "<leader>gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage buffer" },
			{ "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<CR>", desc = "Undo stage hunk" },
			{
				"<leader>gB",
				function()
					package.loaded.gitsigns.blame_line({ full = true })
				end,
				desc = "Blame line",
			},
			{ "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview hunk" },
			{ "<leader>gq", "<cmd>Gitsigns setqflist<CR>", desc = "Quickfix list" },
			{ "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
			{ "<leader>gdd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff this" },
			{ "<leader>gdg", "<cmd>diffget<CR>", desc = "Diff get" },
			{ "<leader>gdp", "<cmd>diffput<CR>", desc = "Diff put" },

			{ "]c", "<cmd>Gitsigns next_hunk<CR>", desc = "Next Git Hunk" },
			{ "[c", "<cmd>Gitsigns prev_hunk<CR>", desc = "Previous Git Hunk" },
		},
	},

	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = { "DiffviewOpen", "DiffviewClose" },
		keys = {
			{ "<leader>gD", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
			{ "<leader>D", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle Diffview" },
		},
		config = function()
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
					disable_defaults = false, -- Keep default keymaps
					diff3 = {
						-- Mappings in 3-way diff layouts
						{
							{ "n", "x" },
							"<leader>go",
							require("diffview.actions").diffget("ours"),
							{ desc = "Obtain the diff hunk from OURS" },
						},
						{
							{ "n", "x" },
							"<leader>gt",
							require("diffview.actions").diffget("theirs"),
							{ desc = "Obtain the diff hunk from THEIRS" },
						},
						{
							"n",
							"g?",
							require("diffview.actions").help({ "view", "diff3" }),
							{ desc = "Open the help panel" },
						},
					},
					diff4 = {
						-- Mappings in 4-way diff layouts
						{
							{ "n", "x" },
							"<leader>gb",
							require("diffview.actions").diffget("base"),
							{ desc = "Obtain the diff hunk from BASE" },
						},
						{
							{ "n", "x" },
							"<leader>go",
							require("diffview.actions").diffget("ours"),
							{ desc = "Obtain the diff hunk from OURS" },
						},
						{
							{ "n", "x" },
							"<leader>gt",
							require("diffview.actions").diffget("theirs"),
							{ desc = "Obtain the diff hunk from THEIRS" },
						},
						{
							"n",
							"g?",
							require("diffview.actions").help({ "view", "diff4" }),
							{ desc = "Open the help panel" },
						},
					},
				},
			})
		end,
	},
}
