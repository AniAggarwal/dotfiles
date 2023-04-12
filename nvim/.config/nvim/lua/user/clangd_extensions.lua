-- extra configuration for clangd
-- Note: setup for the clangd lsp is passed through this plugin rather than
-- masonlsp config
require("clangd_extensions").setup({
	server = {
		cmd = {
			"clangd",
			"-offset-encoding=utf-16",
            "--fallback-style=/home/ani/.config/nvim/language-configs/c/.clang-format"
		},
	},
})
