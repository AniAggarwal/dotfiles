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
			{ "<leader>gB", "<cmd>Gitsigns blame_line full=true<CR>", desc = "Blame line" },
			{ "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview hunk" },
			{ "<leader>gq", "<cmd>Gitsigns setqflist<CR>", desc = "Quickfix list" },
			{ "<leader>gdd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff this" },
			{ "<leader>gdg", "<cmd>diffget<CR>", desc = "Diff get" },
			{ "<leader>gdp", "<cmd>diffput<CR>", desc = "Diff put" },

			{ "]h", "<cmd>Gitsigns nav_hunk next<CR>", desc = "Next Git Hunk" },
			{ "[h", "<cmd>Gitsigns nav_hunk prev<CR>", desc = "Previous Git Hunk" },
		},
	},

	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gD", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
			{ "<leader>D", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle Diffview" },
		},
		config = function()
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
					diff3 = {
						{ { "n", "x" }, "<leader>do", actions.diffget("ours"), { desc = "Diffget from OURS" } },
						{ { "n", "x" }, "<leader>dt", actions.diffget("theirs"), { desc = "Diffget from THEIRS" } },
					},
					diff4 = {
						{ { "n", "x" }, "<leader>db", actions.diffget("base"), { desc = "Diffget from BASE" } },
						{ { "n", "x" }, "<leader>do", actions.diffget("ours"), { desc = "Diffget from OURS" } },
						{ { "n", "x" }, "<leader>dt", actions.diffget("theirs"), { desc = "Diffget from THEIRS" } },
					},
				},
			})
		end,
	},
}
