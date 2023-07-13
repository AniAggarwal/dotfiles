local null_ls = require("null-ls")

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

-- https://github.com/prettier-solidity/prettier-plugin-solidity
null_ls.setup({

	-- Needed to make null-ls use a different than default encoding
	on_init = function(new_client, _)
		new_client.offset_encoding = "utf-16"
	end,

	debug = false,
	sources = {
		-- for Python formatting
		formatting.black.with({
			command = "/home/ani/.local/share/nvim/mason/packages/black/venv/bin/black",
			extra_args = {
				"--line-length",
				"79",
				"--experimental-string-processing",
			},
		}),
		-- for Python imports
		formatting.isort.with({
			command = "/home/ani/.local/share/nvim/mason/packages/isort/venv/bin/isort",
            extra_args = {
                "-SKIP",
                "~/dev/work/*"
            }
		}),
		-- for Lua formatting
		formatting.stylua,

		-- Pass path to custom config file for clang_format
		formatting.clang_format.with({
			extra_args = { "--style=file:/home/ani/.config/nvim/language-configs/c/.clang-format" },
		}),

		-- For Bash/Zsh formatting
		formatting.beautysh.with({
			command = "/home/ani/.local/share/nvim/mason/packages/beautysh/venv/bin/beautysh",
		}),

		-- for Python linting
		diagnostics.flake8.with({
			command = "/home/ani/.local/share/nvim/mason/packages/flake8/venv/bin/flake8",
			extra_args = { "--config=/home/ani/.config/nvim/language-configs/python/.flake8" },
		}),

		-- gitsigns intergration
		null_ls.builtins.code_actions.gitsigns,
	},
})
