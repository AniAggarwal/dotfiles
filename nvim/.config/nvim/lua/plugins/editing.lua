return {
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},

	{
		"ggandor/leap.nvim",
		lazy = false, -- leap lazy loads itself; manual lazy load causes problems
		config = function()
			require("leap").create_default_mappings()
		end,
		dependencies = "tpope/vim-repeat",
	},

	{
		"mrjones2014/smart-splits.nvim",
		build = "./kitty/install-kittens.bash", -- Build step for kitty integration
		lazy = false, -- keybinds won't work if lazy loaded
		keys = {
			-- Resize splits
			{
				"<A-H>",
				function()
					require("smart-splits").resize_left()
				end,
				desc = "Resize left",
			},
			{
				"<A-J>",
				function()
					require("smart-splits").resize_down()
				end,
				desc = "Resize down",
			},
			{
				"<A-K>",
				function()
					require("smart-splits").resize_up()
				end,
				desc = "Resize up",
			},
			{
				"<A-L>",
				function()
					require("smart-splits").resize_right()
				end,
				desc = "Resize right",
			},

			-- Move between splits
			{
				"<C-h>",
				function()
					require("smart-splits").move_cursor_left()
				end,
				desc = "Move to left split",
			},
			{
				"<C-j>",
				function()
					require("smart-splits").move_cursor_down()
				end,
				desc = "Move to down split",
			},
			{
				"<C-k>",
				function()
					require("smart-splits").move_cursor_up()
				end,
				desc = "Move to up split",
			},
			{
				"<C-l>",
				function()
					require("smart-splits").move_cursor_right()
				end,
				desc = "Move to right split",
			},
			{
				"<C-\\>",
				function()
					require("smart-splits").move_cursor_previous()
				end,
				desc = "Move to previous split",
			},

			-- Swap buffers between splits
			{
				"<leader><leader>h",
				function()
					require("smart-splits").swap_buf_left()
				end,
				desc = "Swap buffer left",
			},
			{
				"<leader><leader>j",
				function()
					require("smart-splits").swap_buf_down()
				end,
				desc = "Swap buffer down",
			},
			{
				"<leader><leader>k",
				function()
					require("smart-splits").swap_buf_up()
				end,
				desc = "Swap buffer up",
			},
			{
				"<leader><leader>l",
				function()
					require("smart-splits").swap_buf_right()
				end,
				desc = "Swap buffer right",
			},
		},
	},

	{
		"tpope/vim-repeat",
	},

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter", -- Lazy-load when entering Insert mode
		opts = {
			check_ts = true, -- Enable treesitter integration
		},
		-- TODO: make cmp integreation work
		-- config = function(_, opts)
		--   local npairs = require("nvim-autopairs")
		--   npairs.setup(opts)
		--
		--   -- CMP integration
		--   local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		--   local cmp_status_ok, cmp = pcall(require, "cmp")
		--   if cmp_status_ok then
		--     cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({}))
		--   end
		-- end,
	},

	{
		"numToStr/Comment.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
		keys = {
			{ "gcp", "yy<Plug>(comment_toggle_linewise_current)p", mode = "n", desc = "Comment and copy line" },
			{ "gp", "ygv<Plug>(comment_toggle_linewise_visual)`>p", mode = "x", desc = "Comment and copy selection" },
		},
	},

	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			keywords = {
				-- turning off icons so that gitsigns aren't interrupted
				FIX = { icon = "" },
				TODO = { icon = "" },
				HACK = { icon = "" },
				WARN = { icon = "" },
				PERF = { icon = "" },
				NOTE = { icon = "" },
				TEST = { icon = "" },
			},
		},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next Todo Comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous Todo Comment",
			},
		},
	},

	{
		"folke/which-key.nvim",
		lazy = false,
		opts = {
			preset = "modern",
			win = {
				border = "rounded",
			},
			spec = {
				-- Global mappings
				{ "<leader>w", "<cmd>w<CR>", desc = "Save" },
				{ "<leader>q", "<cmd>q<CR>", desc = "Quit" },
				{ "<leader>Q", "<cmd>q!<CR>", desc = "Quit without saving" },
				{ "<leader>H", "<cmd>nohlsearch<CR>", desc = "Clear highlights" },
				{
					"<leader>L",
					"<cmd>let &colorcolumn=(&colorcolumn == 81 ? 0 : 81)<CR>",
					desc = "Highlight column 81",
				},
				{ "<leader>C", "<cmd>Neogen<CR>", desc = "Generate Documentation" },
				{ "<leader>D", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle Diffview" },
				{
					"g",
					group = "LSP",
					{ "]g", vim.diagnostic.goto_next, desc = "Goto next diagnostic" },
					{ "[g", vim.diagnostic.goto_prev, desc = "Goto prev diagnostic" },
					{ "gd", vim.lsp.buf.definition, desc = "To definition" },
					{ "gD", vim.lsp.buf.declaration, desc = "To declaration" },
					{ "gK", vim.lsp.buf.hover, desc = "Hover" },
					{ "gI", vim.lsp.buf.implementation, desc = "To implementation" },
					{ "gl", vim.diagnostic.open_float, desc = "Open Diagnostic" },
					{ "gf", vim.lsp.buf.format, desc = "Format" },
					{ "gs", vim.lsp.buf.signature_help, desc = "Signature help" },
					{ "ga", vim.lsp.buf.code_action, desc = "Code action" },
					{ "gn", vim.lsp.buf.rename, desc = "Rename" },
					-- TODO: figure out if this is needed or if it automatically works
					-- vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true })
				},
				{
					"z",
					{ "zn", "]s1z=", desc = "Correct next misspelling." },
					{ "zp", "[s1z=", desc = "Correct prev misspelling." },
				},
			},
		},
	},
}
