require("aerial").setup({
	-- backends = { "treesitter", "lsp", "markdown", "man" },
	backends = { "lsp", "treesitter", "markdown", "man" },
	layout = {
		-- These control the width of the aerial window.
		-- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
		-- min_width and max_width can be a list of mixed types.
		-- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
		min_width = { 20, 0.1 },
		max_width = { 120, 0.3 },
		default_direction = "prefer_right",
	},
})
