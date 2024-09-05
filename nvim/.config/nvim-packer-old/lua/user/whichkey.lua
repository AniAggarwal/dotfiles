local wk = require("which-key")

wk.setup({
    preset = "modern",
	win = {
		border = "rounded",
	},
})

wk.add({
  -- Global mappings
  { "<leader>w", "<cmd>w<CR>", desc = "Save" },
  { "<leader>q", "<cmd>q<CR>", desc = "Quit" },
  { "<leader>Q", "<cmd>q!<CR>", desc = "Quit without saving" },
  { "<leader>H", "<cmd>nohlsearch<CR>", desc = "Clear highlights" },
  { "<leader>L", "<cmd>let &colorcolumn=(&colorcolumn == 81 ? 0 : 81)<CR>", desc = "Highlight column 81" },
  { "<leader>C", "<cmd>Neogen<CR>", desc = "Generate Documentation" },
  { "<leader>D", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle Diffview" },

  -- NvimTree
  { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Explorer" },

  -- Telescope
  {
    "<leader>f",
    group = "Telescope",
    { "<leader>fr", "<cmd>Telescope resume<CR>", desc = "Resume" },
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>ft", "<cmd>Telescope live_grep<CR>", desc = "Find text in project" },
    { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "Projects" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
    { "<leader>fl", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Current buffer" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
    { "<leader>fT", "<cmd>Trouble<CR>", desc = "Trouble" },
    { "<leader>fL", "<cmd>Legendary<CR>", desc = "Search with Legendary" },
  },

  -- Git
  {
    "<leader>g",
    group = "Git",
    { "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage hunk" },
    { "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset hunk" },
    { "<leader>gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage buffer" },
    { "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<CR>", desc = "Undo stage hunk" },
    { "<leader>gB", function() package.loaded.gitsigns.blame_line({ full = true }) end, desc = "Blame line" },
    { "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview hunk" },
    { "<leader>gq", "<cmd>Gitsigns setqflist<CR>", desc = "Quickfix list" },
    { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    { "<leader>gD", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
    {
      "<leader>gd",
      group = "GitDiff",
      { "<leader>gdd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff this" },
      { "<leader>gdg", "<cmd>diffget<CR>", desc = "Diff get" },
      { "<leader>gdp", "<cmd>diffput<CR>", desc = "Diff put" },
    },
  },

  -- Symbols outline
  { "<leader>s", "<cmd>AerialToggle<CR>", desc = "Symbols Outline" },

  -- Nvim DAP
  {
    "<leader>d",
    group = "DAP",
    { "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", desc = "Toggle breakpoint" },
    { "<leader>dB", "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", desc = "Set breakpoint" },
    { "<leader>de", "<cmd>lua require'dap'.set_exception_breakpoints({'all'})<CR>", desc = "Exception breakpoints" },
    { "<leader>dl", "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", desc = "Log point" },
    { "<leader>dS", "<cmd>lua require'dap'.close()<CR>", desc = "Stop" },
    { "<leader>dk", "<cmd>lua require'dap.ui.widgets'.hover()<CR>", desc = "Hover info" },
    { "<leader>du", "<cmd>lua require'dapui'.toggle()<CR>", desc = "Toggle DAP UI" },
    { "<leader>dc", require("jdtls").test_class, desc = "Unit test class" },
    { "<leader>dm", require("jdtls").test_nearest_method, desc = "Unit test nearest method" },
    { "<leader>dr", require("dap").repl.open, desc = "Open REPL" },
  },
}, { mode = "n" })

-- Leader maps in visual mode
wk.add({
  {
    "<leader>g",
    group = "Git",
    { "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage hunk" },
    { "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset hunk" },
  }
}, { mode = "v" })

-- Normal mode maps
wk.add({
  {
    "g",
    group = "LSP",
    { "gd", vim.lsp.buf.definition, desc = "To definition" },
    { "gD", vim.lsp.buf.declaration, desc = "To declaration" },
    { "gK", vim.lsp.buf.hover, desc = "Hover" },
    { "gI", vim.lsp.buf.implementation, desc = "To implementation" },
    { "gl", vim.diagnostic.open_float, desc = "Open Diagnostic" },
    { "gf", vim.lsp.buf.format, desc = "Format" },
    { "gs", vim.lsp.buf.signature_help, desc = "Signature help" },
    { "ga", vim.lsp.buf.code_action, desc = "Code action" },
    { "gn", vim.lsp.buf.rename, desc = "Rename" },
  },
  {
    "z",
    group = "Spell",
    { "zn", "]s1z=", desc = "Correct next misspelling." },
    { "zp", "[s1z=", desc = "Correct prev misspelling." },
  }
}, { mode = "n" })

-- Visual mode maps
wk.add({
  {
    "g",
    group = "LSP",
    { "gf", vim.lsp.buf.range_formatting, desc = "Range Format" },
    { "ga", vim.lsp.buf.code_action, desc = "Code action" },
  }
}, { mode = "v" })

-- OLD CONFIG, v2

-- local which_key = require("which-key")
--
-- which_key.setup({
-- 	window = {
-- 		border = "rounded", -- none, single, double, shadow
-- 		position = "bottom", -- bottom, top
-- 		margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
-- 		padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
-- 		winblend = 0,
-- 	},
-- })
--
-- -- Leader maps in normal mode
-- which_key.register({
-- 	w = { "<cmd>w<CR>", "Save" },
-- 	q = { "<cmd>q<CR>", "Quit" },
-- 	Q = { "<cmd>q!<CR>", "Quit without saving" },
-- 	H = { "<cmd>nohlsearch<CR>", "Clear highlights" },
-- 	L = { "<cmd>let &colorcolumn=(&colorcolumn == 81 ? 0 : 81)<CR>", "Highlight column 81" },
-- 	C = { "<cmd>Neogen<CR>", "Generate Documentation" },
-- 	D = { "<cmd>DiffviewToggleFiles<CR>", "Toggle Diffview" },
--
-- 	-- NvimTree
-- 	e = { "<cmd>NvimTreeToggle<CR>", "Explorer" },
--
-- 	-- Telescope
-- 	f = {
-- 		name = "Telescope",
-- 		r = { "<cmd>Telescope resume<CR>", "Resume" },
-- 		f = { "<cmd>Telescope find_files<CR>", "Find files" },
-- 		t = { "<cmd>Telescope live_grep<CR>", "Find text in project" },
-- 		p = { "<cmd>Telescope projects<CR>", "Projects" },
-- 		b = { "<cmd>Telescope buffers<CR>", "Buffers" },
-- 		c = { "<cmd>Telescope commands<CR>", "Commands" },
-- 		l = { "<cmd>Telescope current_buffer_fuzzy_find<CR>", "Current buffer" },
-- 		d = { "<cmd>Telescope diagnostics<CR>", "Diagnostics" },
-- 		s = { "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols" },
-- 		T = { "<cmd>Trouble<CR>", "Trouble Search" },
-- 		L = { "<cmd>Legendary<CR>", "Search with Legendary" },
-- 	},
--
-- 	-- Git
-- 	g = {
-- 		name = "Git",
-- 		s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage hunk" },
-- 		r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset hunk" },
-- 		S = { "<cmd>Gitsigns stage_buffer<CR>", "Stage buffer" },
-- 		u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Undo stage hunk" },
-- 		B = {
-- 			function()
-- 				package.loaded.gitsigns.blame_line({ full = true })
-- 			end,
-- 			"Blame line",
-- 		},
-- 		p = { "<cmd>Gitsigns preview_hunk<CR>", "Preview hunk" },
-- 		q = { "<cmd>Gitsigns setqflist<CR>", "Quickfix list" },
-- 		g = { "<cmd>LazyGit<CR>", "LazyGit" },
--
-- 		D = { "<cmd>DiffviewOpen<CR>", "Open Diffview" },
-- 		d = {
-- 			d = { "<cmd>Gitsigns diffthis<CR>", "Diff this" },
-- 			g = { "<cmd>diffget<CR>", "Diff get" },
-- 			p = { "<cmd>diffput<CR>", "Diff put" },
-- 		},
-- 	},
--
-- 	-- Symbols outline
-- 	s = {
-- 		"<cmd>AerialToggle<CR>",
-- 		"Symbols Outline",
-- 	},
--
-- 	-- Nvim DAP
-- 	d = {
-- 		name = "DAP",
-- 		b = { "<cmd>lua require'dap'.toggle_breakpoint()<CR>", "Toggle breakpoint" },
-- 		B = { "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", "Set breakpoint" },
-- 		e = { "<cmd>lua require'dap'.set_exception_breakpoints({'all'})<CR>", "Exception breakpoints" },
-- 		l = { "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", "Log point" },
-- 		s = { "<cmd>lua require'dap'.continue()<CR>", "Stop" },
-- 		S = { "<cmd>lua require'dap'.terminate()<CR>", "Stop" },
-- 		k = { "<cmd>lua require'dap.ui.widgets'.hover()<CR>", "Hover info" },
-- 		u = { "<cmd>lua require'dapui'.toggle()<CR>", "Toggle DAP UI" },
-- 		c = { require("jdtls").test_class, "Unit test class" },
-- 		m = { require("jdtls").test_nearest_method, "Unit test nearest method" },
--
-- 		r = { require("dap").repl.open, "Open REPL" },
-- 	},
-- }, { prefix = "<leader>", mode = "n" })
--
-- -- Leader maps in visual mode
-- which_key.register({
-- 	h = {
-- 		name = "Git",
-- 		s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage hunk" },
-- 		r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset hunk" },
-- 	},
-- }, { prefix = "<leader>", mode = "v" })
--
-- -- Normal mode maps
-- which_key.register({
-- 	g = {
-- 		r = { "<cmd>TroubleToggle lsp_references<CR>", "References" },
-- 		L = { "<cmd>TroubleToggle document_diagnostics<CR>", "Document diagnostics" },
--
-- 		-- These are global but only work on certain LSPs
-- 		d = { vim.lsp.buf.definition, "To definition" },
-- 		D = { vim.lsp.buf.declaration, "To declaration" },
-- 		K = { vim.lsp.buf.hover, "Hover" },
-- 		I = { vim.lsp.buf.implementation, "To implementation" },
-- 		l = { vim.diagnostic.open_float, "Open Diagnostic" },
-- 		f = { vim.lsp.buf.format, "Format" },
-- 		s = { vim.lsp.buf.signature_help, "Signature help" },
-- 		a = { vim.lsp.buf.code_action, "Code action" },
-- 		n = { vim.lsp.buf.rename, "Rename" },
-- 	},
-- 	z = {
-- 		n = { "]s1z=", "Correct next misspelling." },
-- 		p = { "[s1z=", "Correct prev misspelling." },
-- 	},
-- }, { prefix = "", mode = "n" })
--
-- -- Visual mode maps
-- which_key.register({
-- 	g = {
-- 		-- These are global but only work on certain LSPs
-- 		f = { vim.lsp.buf.range_formatting, "Range Format" },
-- 		a = { vim.lsp.buf.code_action, "Code action" },
-- 	},
-- }, { prefix = "", mode = "v" })
