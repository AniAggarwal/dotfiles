-- One set of vim motions, three layers: Neovim splits, herdr panes, kitty
-- windows. Only the outer layer differs by context — herdr-splits drives herdr
-- when Neovim runs inside a pane, smart-splits drives kitty when it does not —
-- so exactly one of them owns <C-hjkl> and <A-S-hjkl> at any time. Buffer
-- swapping is Neovim-internal either way, so smart-splits keeps it in both
-- worlds and escalates outward by hand at an edge.
local in_herdr = vim.env.HERDR_ENV == "1"
local chain = vim.fn.expand("~/.config/herdr/local-plugins/herdr-kitty-chain/scripts")

local dir_key = { left = "h", down = "j", up = "k", right = "l" }

---Hand a chord to the kitty layer. Runs detached; `on_fail` fires when kitty
---has no window that way, which is the caller's cue to stay put or wrap.
local function kitty_escape(action, direction, on_fail)
	vim.system({ chain .. "/kitty-escape.sh", action, direction }, {}, function(result)
		if result.code ~= 0 and on_fail then
			vim.schedule(on_fail)
		end
	end)
end

---<C-A-S-hjkl>: swap with the neighbour in `direction`, crossing out of Neovim
---when there is no split that way. herdr-splits has no swap action of its own,
---so the herdr hop is made here.
local function swap(direction)
	return function()
		if vim.fn.winnr(dir_key[direction]) ~= vim.fn.winnr() then
			require("smart-splits")["swap_buf_" .. direction]()
			return
		end
		if not in_herdr then
			kitty_escape("move", direction)
			return
		end
		vim.system({ "herdr", "pane", "swap", "--direction", direction, "--current" }, {}, function(result)
			if result.code ~= 0 then
				kitty_escape("move", direction)
			end
		end)
	end
end

return {
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},

	{
		url = "https://codeberg.org/andyg/leap.nvim",
		lazy = false,
		config = function()
			-- Sneak-style mappings (replaces deprecated create_default_mappings)
			vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
			vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")
		end,
		dependencies = "tpope/vim-repeat",
	},

	{
		"mrjones2014/smart-splits.nvim",
		build = "./kitty/install-kittens.bash", -- Build step for kitty integration
		lazy = false, -- keybinds won't work if lazy loaded
		-- Swapping is Neovim-internal, so it is bound in both worlds. Navigation
		-- and resize are not: under herdr they belong to herdr-splits, and binding
		-- both plugins to the same chords is what its README warns against.
		keys = vim.list_extend({
			{
				"<C-A-S-h>",
				swap("left"),
				mode = { "n", "t" },
				desc = "Swap window left",
			},
			{
				"<C-A-S-j>",
				swap("down"),
				mode = { "n", "t" },
				desc = "Swap window down",
			},
			{
				"<C-A-S-k>",
				swap("up"),
				mode = { "n", "t" },
				desc = "Swap window up",
			},
			{
				"<C-A-S-l>",
				swap("right"),
				mode = { "n", "t" },
				desc = "Swap window right",
			},
		}, in_herdr and {} or {
			-- Resize splits (including from terminal mode)
			{
				"<A-H>",
				function()
					require("smart-splits").resize_left()
				end,
				mode = { "n", "t" },
				desc = "Resize left",
			},
			{
				"<A-J>",
				function()
					require("smart-splits").resize_down()
				end,
				mode = { "n", "t" },
				desc = "Resize down",
			},
			{
				"<A-K>",
				function()
					require("smart-splits").resize_up()
				end,
				mode = { "n", "t" },
				desc = "Resize up",
			},
			{
				"<A-L>",
				function()
					require("smart-splits").resize_right()
				end,
				mode = { "n", "t" },
				desc = "Resize right",
			},

			-- Move between splits (including from terminal mode)
			{
				"<C-h>",
				function()
					require("smart-splits").move_cursor_left()
				end,
				mode = { "n", "t" },
				desc = "Move to left split",
			},
			{
				"<C-j>",
				function()
					require("smart-splits").move_cursor_down()
				end,
				mode = { "n", "t" },
				desc = "Move to down split",
			},
			{
				"<C-k>",
				function()
					require("smart-splits").move_cursor_up()
				end,
				mode = { "n", "t" },
				desc = "Move to up split",
			},
			{
				"<C-l>",
				function()
					require("smart-splits").move_cursor_right()
				end,
				mode = { "n", "t" },
				desc = "Move to right split",
			},
			{
				"<C-;>",
				function()
					require("smart-splits").move_cursor_previous()
				end,
				mode = { "n", "t" },
				desc = "Move to previous split",
			},
		}),
	},

	-- The herdr half of the chain: makes herdr panes behave like Neovim splits,
	-- exactly as smart-splits does for kitty windows.
	{
		"lmilojevicc/herdr-splits.nvim",
		cond = in_herdr,
		lazy = false, -- same reason as smart-splits: keybinds must exist at startup
		config = function()
			require("herdr-splits").setup({
				-- Resize on <A-S-hjkl> rather than the plugin's <A-hjkl> default: it
				-- matches the kitty binding it replaces, and it leaves alt+l free to
				-- stay "clear the terminal". Written through to herdr-splits.conf, so
				-- the herdr-side scripts forward the same chord.
				resize_keys = { left = "<A-S-h>", down = "<A-S-j>", up = "<A-S-k>", right = "<A-S-l>" },
				-- Stand-in for the herdr binary that escalates a resize to kitty when
				-- the herdr pane already spans its tab; everything else passes through.
				herdr_bin = chain .. "/herdr-shim.sh",
				-- Reached only once there is no Neovim split AND no herdr pane in this
				-- direction, so a kitty window is the last thing left to try. Wrap
				-- inside Neovim only when kitty has nowhere to go either.
				at_edge = function(ctx)
					kitty_escape("focus", ctx.direction, ctx.wrap)
				end,
			})
		end,
		keys = {
			{
				"<C-h>",
				function()
					require("herdr-splits").move_cursor_left()
				end,
				mode = { "n", "t" },
				desc = "Move to left split",
			},
			{
				"<C-j>",
				function()
					require("herdr-splits").move_cursor_down()
				end,
				mode = { "n", "t" },
				desc = "Move to down split",
			},
			{
				"<C-k>",
				function()
					require("herdr-splits").move_cursor_up()
				end,
				mode = { "n", "t" },
				desc = "Move to up split",
			},
			{
				"<C-l>",
				function()
					require("herdr-splits").move_cursor_right()
				end,
				mode = { "n", "t" },
				desc = "Move to right split",
			},
			{
				"<A-H>",
				function()
					require("herdr-splits").resize_left()
				end,
				mode = { "n", "t" },
				desc = "Resize left",
			},
			{
				"<A-J>",
				function()
					require("herdr-splits").resize_down()
				end,
				mode = { "n", "t" },
				desc = "Resize down",
			},
			{
				"<A-K>",
				function()
					require("herdr-splits").resize_up()
				end,
				mode = { "n", "t" },
				desc = "Resize up",
			},
			{
				"<A-L>",
				function()
					require("herdr-splits").resize_right()
				end,
				mode = { "n", "t" },
				desc = "Resize right",
			},
		},
	},

	{
		"tpope/vim-repeat",
	},

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter", -- Lazy-load when entering Insert mode
		config = function()
			require("nvim-autopairs").setup({
				check_ts = true, -- Enable treesitter integration
			})
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
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
				{ "<leader>g", group = "Git" },
				{ "<leader>f", group = "Find" },
				{ "<leader>d", group = "Debug" },
				{ "<leader>a", group = "AI" },
				{ "]", group = "Next" },
				{ "[", group = "Prev" },
				{
					"g",
					group = "LSP",
					{
						"]g",
						function()
							vim.diagnostic.jump({ count = 1, float = true })
						end,
						desc = "Next diagnostic",
					},
					{
						"[g",
						function()
							vim.diagnostic.jump({ count = -1, float = true })
						end,
						desc = "Prev diagnostic",
					},
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
