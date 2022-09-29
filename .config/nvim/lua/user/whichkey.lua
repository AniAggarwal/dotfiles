local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	return
end

-- TODO set up manual keybinds
which_key.setup({
	window = {
		border = "rounded", -- none, single, double, shadow
		position = "bottom", -- bottom, top
		margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
		padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
		winblend = 0,
	},
})

-- Leader maps in normal mode
which_key.register({
	w = { "<cmd>w<CR>", "Save" },
	q = { "<cmd>q<CR>", "Quit" },
	Q = { "<cmd>q!<CR>", "Quit without saving" },
	H = { "<cmd>nohlsearch<CR>", "Clear highlights" },
	c = { "<cmd>let &colorcolumn=(&colorcolumn == 81 ? 0 : 81)<CR>", "Highlight column 81" },

	-- NvimTree
	e = { "<cmd>NvimTreeToggle<CR>", "Explorer" },

	-- Telescope
	-- TODO look into using Telescope for marks and jumplist
	f = {
		name = "Telescope",
		r = { "<cmd>Telescope resume<CR>", "Resume" },
		f = { "<cmd>Telescope find_files<CR>", "Find files" },
		t = { "<cmd>Telescope live_grep<CR>", "Find text in project" },
		p = { "<cmd>Telescope projects<CR>", "Projects" },
		b = { "<cmd>Telescope buffers<CR>", "Buffers" },
		c = { "<cmd>Telescope commands<CR>", "Commands" },
		l = { "<cmd>Telescope current_buffer_fuzzy_find<CR>", "Current buffer" },
		d = { "<cmd>Telescope diagnostics<CR>", "Diagnostics" },
		s = { "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols" },
		T = { "<cmd>TodoTelescope<CR>", "Search TODOs" },
	},

	-- Git
	h = {
		name = "Git",
		s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage hunk" },
		r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset hunk" },
		S = { "<cmd>Gitsigns stage_buffer<CR>", "Stage buffer" },
		u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Undo stage hunk" },
		b = {
			function()
				package.loaded.gitsigns.blame_line({ full = true })
			end,
			"Blame line",
		},
		p = { "<cmd>Gitsigns preview_hunk<CR>", "Preview hunk" },
		q = { "<cmd>Gitsigns setqflist<CR>", "Quickfix list" },
		d = { "<cmd>Gitsigns diffthis<CR>", "Diff this" },
		g = { "<cmd>LazyGit<CR>", "LazyGit" },
	},

	-- Symbols outline
	s = {
		"<cmd>SymbolsOutline<CR>",
		"Symbols Outline",
	},
}, { prefix = "<leader>", mode = "n" })

-- Leader maps in visual mode
which_key.register({
	h = {
		name = "Git",
		s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage hunk" },
		r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset hunk" },
	},
}, { prefix = "<leader>", mode = "v" })

-- Normal mode maps
which_key.register({
	g = {
		r = { "<cmd>TroubleToggle lsp_references<CR>", "References" },
		L = { "<cmd>TroubleToggle document_diagnostics<CR>", "Document diagnostics" },

		-- These are global but only work on certain LSPs
		d = { vim.lsp.buf.definition, "To definition" },
		D = { vim.lsp.buf.declaration, "To declaration" },
		K = { vim.lsp.buf.hover, "Hover" },
		I = { vim.lsp.buf.implementation, "To implementation" },
		l = { vim.diagnostic.open_float, "Open Diagnostic" },
		f = { vim.lsp.buf.formatting, "Format" },
		s = { vim.lsp.buf.signature_help, "Signature help" },
		a = { vim.lsp.buf.code_action, "Code action" },
		n = { vim.lsp.buf.rename, "Rename" },

		-- TODO make this work
		-- keymap("n", "gcp", "yy <bar> gcc <bar> p", opts)
	},
}, { prefix = "", mode = "n" })

-- Visual mode maps
which_key.register({
	g = {
		-- These are global but only work on certain LSPs
		f = { vim.lsp.buf.range_formatting, "Range Format" },
		a = { vim.lsp.buf.code_action, "Code action" },
	},
}, { prefix = "", mode = "v" })
