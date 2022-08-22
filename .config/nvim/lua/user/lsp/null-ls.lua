local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

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
		formatting.stylua, -- for Lua formatting

        -- for Python linting
		diagnostics.flake8.with ({
			command = "/home/ani/miniconda3/envs/nvim/bin/flake8",
		}),
	},
})
