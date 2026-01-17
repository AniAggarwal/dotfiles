return {
	-- Amp.nvim - Sourcegraph AI agent integration
	{
		"sourcegraph/amp.nvim",
		branch = "main",
		lazy = false,
		opts = {
			auto_start = true,
			log_level = "info",
		},
	},

	-- Claude Code - Neovim integration for Claude Code CLI
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		config = true,
		opts = {
			auto_start = true,
			log_level = "info",
			terminal = {
				split_side = "right",
				split_width_percentage = 0.30,
				provider = "snacks",
			},
		},
		keys = {
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude Code", mode = "v" },
		},
	},

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {},
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = "zbirenbaum/copilot.lua",
		opts = {
			method = "getCompletionsCycling",
			filetypes = {
				VimspectorPrompt = false, -- Disable Copilot in VimspectorPrompt filetypes
			},
		},
	},
	{
		{
			"CopilotC-Nvim/CopilotChat.nvim",
			dependencies = {
				{ "nvim-lua/plenary.nvim", branch = "master" },
				{ "zbirenbaum/copilot.lua" },
				{ "nvim-lua/plenary.nvim" },
			},
			build = "make tiktoken",
			opts = {
				model = "claude-opus-4.5",
				window = {
					layout = "vertical",
					width = 0.3,
					border = "rounded",
				},
			},
		},
	},
}
