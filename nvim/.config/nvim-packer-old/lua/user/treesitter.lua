require("nvim-treesitter.configs").setup({
	ensure_installed = { "python", "c", "lua", "bash", "ocaml" }, -- one of "all" or a list of languages
	auto_install = true,
	ignore_install = { "latex" }, -- List of parsers to ignore installing
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = { "latex" }, -- list of language that will be disabled
	},
	autopairs = {
		enable = true,
	},
	indent = {
		enable = true,
		-- python indentation doesn't work well with treesitter
		disable = { "python", "latex" },
	},
})
-- treesitter is being used for folding; if running into issues, reference: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Installation#packernvim
