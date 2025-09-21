-- Soft wrapping and spell checking for markdown files
vim.opt_local.wrap = true
vim.opt_local.tw = 0
vim.opt_local.spell = true

-- Remap gj, gk to j, k for wrapped line navigation
vim.keymap.set({ "n", "x" }, "j", "gj", { noremap = true, silent = true, buffer = true })
vim.keymap.set({ "n", "x" }, "k", "gk", { noremap = true, silent = true, buffer = true })
