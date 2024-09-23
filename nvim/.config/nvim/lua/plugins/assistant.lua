return {
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
}
