return {
	{
		"danymat/neogen",
		cmd = "Neogen",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		keys = {
			{ "<leader>C", "<cmd>Neogen<CR>", desc = "Generate Documentation" },
		},
		opts = {
			snippet_engine = "luasnip",
			build = "make install_jsregexp",
			languages = {
				python = { templates = { "google_docstrings" } },
			},
		},
	},

	-- Snippets
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter", -- Lazy load when entering Insert mode
		dependencies = {
			{ "hrsh7th/cmp-buffer" }, -- Completions based on current buffer contents
			{ "hrsh7th/cmp-path" }, -- System path completions
			{ "hrsh7th/cmp-nvim-lsp" }, -- LSP completions
			{ "hrsh7th/cmp-nvim-lsp-document-symbol" }, -- Symbols
			{ "hrsh7th/cmp-nvim-lsp-signature-help" }, -- Method signature help
			{ "saadparwaiz1/cmp_luasnip" }, -- Snippet completions
			{ "onsails/lspkind.nvim" }, -- Icons for completion items
			{ "hrsh7th/cmp-nvim-lua" }, -- Neovim Lua API completions

			{ "L3MON4D3/LuaSnip" }, -- Snippet engine for cmp_luasnip
			{ "rafamadriz/friendly-snippets" }, -- Extra snippets
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			local source_names = {
				copilot = "[ COPILOT]",
				nvim_lsp = "[󰒋LSP]",
				nvim_lsp_signature_help = "[󰃣 SIGNATURE]",
				path = "[~ PATH]",
				luasnip = "[󰆐 Snippet]",
				buffer = "[ Buffer]",
			}

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping.abort(),

					["<Tab>"] = cmp.mapping(function(fallback)
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, {
						"i",
						"s",
					}),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, {
						"i",
						"s",
					}),

					-- TODO: figure out if I need this workaround
					-- ["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<CR>"] = function(fallback)
						-- Don't block <CR> if signature help is active
						-- https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/issues/13
						if
							not cmp.visible()
							or not cmp.get_selected_entry()
							or cmp.get_selected_entry().source.name == "nvim_lsp_signature_help"
						then
							fallback()
						else
							cmp.confirm({
								-- Replace word if completing in the middle of a word
								-- https://github.com/hrsh7th/nvim-cmp/issues/664
								behavior = cmp.ConfirmBehavior.Replace,
								-- Don't select first item on CR if nothing was selected
								select = false,
							})
						end
					end,
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
		end,
	},
}
