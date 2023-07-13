-- Require cmp and luasnip are installed
local cmp = require("cmp")
local luasnip = require("luasnip")

-- Nicer symbols
local lspkind = require("lspkind")

-- Allow vscode-like snippets to be loaded (i.e. friendly-snippets)
require("luasnip/loaders/from_vscode").lazy_load()

local source_names = {
	copilot = "[ COPILOT]",
	nvim_lsp = "[󰒋LSP]",
	nvim_lsp_signature_help = "[󰃣 SIGNATURE]",
	path = "[~ PATH]",
	luasnip = "[󰆐 Snippet]",
	buffer = "[ Buffer]",
}

local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

cmp.setup({
	-- Using luasnip as my snippet engine
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},

	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = false }),

		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			elseif has_words_before() then
				cmp.complete()
			else
				fallback()
			end
		end, { "i", "s" }),

		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = lspkind.cmp_format({
			mode = "symbol", -- show only symbol annotations
			-- maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
			-- The function below will be called before any actual modifications from lspkind
			-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
			before = function(entry, vim_item)
				vim_item.menu = source_names[entry.source.name]
				return vim_item
			end,
		}),
	},

	-- Order matters: nvim_lsp is shown before nvim_lua in this case
	sources = cmp.config.sources({
		{ name = "copilot", keyword_length = 0, max_item_count = 5 }, -- Github copilot
		{ name = "luasnip" }, -- snippets
		{ name = "nvim_lsp" }, -- native lsp
		{ name = "nvim_lsp_signature_help" }, -- Display method signatures while typing
		{ name = "nvim_lua" }, -- Neovim's lua api
		{ name = "buffer" }, -- based on current items in buffer
		{ name = "path" }, -- based on filesystem paths
	}),
	confirm_opts = {
		behavior = cmp.ConfirmBehavior.Replace,
		select = false,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	experimental = {
		ghost_text = true, -- preview completion text
	},

	-- Adding line for custom sorting for clangd
	sorting = {
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.recently_used,
			require("clangd_extensions.cmp_scores"),
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
})

-- Color the icons in the completion menu
vim.cmd([[
  highlight! link CmpItemMenu Comment
  " gray
  highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=#808080
  " blue
  highlight! CmpItemAbbrMatch guibg=NONE guifg=#569CD6
  highlight! CmpItemAbbrMatchFuzzy guibg=NONE guifg=#569CD6
  " light blue
  highlight! CmpItemKindVariable guibg=NONE guifg=#9CDCFE
  highlight! CmpItemKindInterface guibg=NONE guifg=#9CDCFE
  highlight! CmpItemKindText guibg=NONE guifg=#9CDCFE
  " pink
  highlight! CmpItemKindFunction guibg=NONE guifg=#C586C0
  highlight! CmpItemKindMethod guibg=NONE guifg=#C586C0
  " front
  highlight! CmpItemKindKeyword guibg=NONE guifg=#D4D4D4
  highlight! CmpItemKindProperty guibg=NONE guifg=#D4D4D4
  highlight! CmpItemKindUnit guibg=NONE guifg=#D4D4D4
]])
