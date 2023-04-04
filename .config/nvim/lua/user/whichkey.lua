local which_key = require("which-key")

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
		L = { "<cmd>Legendary<CR>", "Search with Legendary" },
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

	-- Nvim DAP
	d = {
		name = "DAP",
		b = { "<cmd>lua require'dap'.toggle_breakpoint()<CR>", "Toggle breakpoint" },
		B = { "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", "Set breakpoint" },
		e = { "<cmd>lua require'dap'.set_exception_breakpoints({'all'})<CR>", "Exception breakpoints" },
		l = { "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", "Log point" },

		S = { "<cmd>lua require'dap'.close()<CR>", "Stop" },
		k = { "<cmd>lua require'dap.ui.widgets'.hover()<CR>", "Hover info" },
		u = { "<cmd>lua require'dapui'.toggle()<CR>", "Toggle DAP UI" },
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
		f = { vim.lsp.buf.format, "Format" },
		s = { vim.lsp.buf.signature_help, "Signature help" },
		a = { vim.lsp.buf.code_action, "Code action" },
		n = { vim.lsp.buf.rename, "Rename" },
	},
	z = {
		n = { "]s1z=", "Correct next misspelling." },
		p = { "[s1z=", "Correct prev misspelling." },
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
