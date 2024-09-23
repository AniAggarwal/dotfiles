return {

	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvimtools/none-ls-extras.nvim",
			"jay-babu/mason-null-ls.nvim",
			"williamboman/mason.nvim",
		},
		config = function()
			local null_ls = require("null-ls")
			local mason_null_ls = require("mason-null-ls")

			-- List of sources you want to manage with mason-null-ls
			mason_null_ls.setup({
				ensure_installed = {
					"black", -- Python formatter
					"isort", -- Python import sorter
					"flake8", -- Python linter
					"stylua", -- Lua formatter
					"beautysh", -- Bash/Zsh formatter
					"prettier", -- Formatter for Markdown, JSON, YAML, etc.
				},
				automatic_installation = true, -- Automatically install sources if they're not installed
			})

			null_ls.setup({
				sources = {
					null_ls.builtins.code_actions.gitsigns,

					-- Python
					null_ls.builtins.formatting.black.with({
						extra_args = { "--line-length", "79" },
					}),
					require("none-ls.diagnostics.flake8").with({
						extra_args = {
							"--config=" .. os.getenv("HOME") .. "/.config/nvim/language-configs/python/.flake8",
						},
					}),
					null_ls.builtins.formatting.isort,

					-- Lua
					null_ls.builtins.formatting.stylua,

					-- C
					null_ls.builtins.formatting.clang_format.with({
						extra_args = {
							"--style=file:" .. os.getenv("HOME") .. "/.config/nvim/language-configs/c/.clang-format",
						},
					}),

					-- Bash/Zsh
					require("none-ls.formatting.beautysh"),

					-- Markdown, JSON, YAML, etc.
					null_ls.builtins.formatting.prettier,
				},
			})
		end,
	},
}
