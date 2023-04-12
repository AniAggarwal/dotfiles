require("nvim-treesitter.configs").setup({
	ensure_installed = "all", -- one of "all" or a list of languages
	auto_install = true,
	ignore_install = { "" }, -- List of parsers to ignore installing
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = {}, -- list of language that will be disabled
	},
	autopairs = {
		enable = true,
	},
	indent = {
		enable = true,
		-- python indentation doesn't work well with treesitter
		disable = { "python" },
	},
})
-- treesitter is being used for folding; if running into issues, reference: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Installation#packernvim
