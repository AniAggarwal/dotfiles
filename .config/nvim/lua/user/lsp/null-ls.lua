null_ls = require("null-ls")

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

-- https://github.com/prettier-solidity/prettier-plugin-solidity
null_ls.setup({
	debug = false,
	sources = {
        -- for Python formatting
		formatting.black.with ({
			command = "/usr/bin/black",
		}),
        -- for Python imports
		formatting.isort.with ({
			command = "/home/ani/miniconda3/envs/nvim/bin/isort",
		}),
         -- for Lua formatting
		formatting.stylua,

        -- for Python linting
		diagnostics.flake8.with ({
			command = "/home/ani/miniconda3/envs/nvim/bin/flake8",
		}),

        -- gitsigns intergration
        null_ls.builtins.code_actions.gitsigns,
	},
})
