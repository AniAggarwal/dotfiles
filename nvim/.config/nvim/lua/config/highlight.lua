-- Same CmpItemMenu color as Comment
vim.api.nvim_set_hl(0, "CmpItemMenu", { link = "Comment" })

-- Set highlights for Cmp items
vim.api.nvim_set_hl(0, "CmpItemAbbrDeprecated", { bg = "NONE", fg = "#808080", strikethrough = true })
vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { bg = "NONE", fg = "#569CD6" })
vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { bg = "NONE", fg = "#569CD6" })

-- Light blue highlights
vim.api.nvim_set_hl(0, "CmpItemKindVariable", { bg = "NONE", fg = "#9CDCFE" })
vim.api.nvim_set_hl(0, "CmpItemKindInterface", { bg = "NONE", fg = "#9CDCFE" })
vim.api.nvim_set_hl(0, "CmpItemKindText", { bg = "NONE", fg = "#9CDCFE" })

-- Pink highlights
vim.api.nvim_set_hl(0, "CmpItemKindFunction", { bg = "NONE", fg = "#C586C0" })
vim.api.nvim_set_hl(0, "CmpItemKindMethod", { bg = "NONE", fg = "#C586C0" })

-- Front highlights (grayish-white)
vim.api.nvim_set_hl(0, "CmpItemKindKeyword", { bg = "NONE", fg = "#D4D4D4" })
vim.api.nvim_set_hl(0, "CmpItemKindProperty", { bg = "NONE", fg = "#D4D4D4" })
vim.api.nvim_set_hl(0, "CmpItemKindUnit", { bg = "NONE", fg = "#D4D4D4" })

-- Define Diagnostic Signs without text and with number highlights
vim.fn.sign_define("DiagnosticSignError", { numhl = "LspDiagnosticsLineNrError", text = "" })
vim.fn.sign_define("DiagnosticSignWarn", { numhl = "LspDiagnosticsLineNrWarning", text = "" })
vim.fn.sign_define("DiagnosticSignInformation", { numhl = "LspDiagnosticsLineNrInfo", text = "" })
vim.fn.sign_define("DiagnosticSignHint", { numhl = "LspDiagnosticsLineNrHint", text = "" })

-- Set highlight groups for diagnostic signs with foreground, background colors, and bold text
vim.api.nvim_set_hl(0, "LspDiagnosticsLineNrError", { fg = "#eb6f92", bg = "#412d44", bold = true })
vim.api.nvim_set_hl(0, "LspDiagnosticsLineNrWarning", { fg = "#f6c177", bg = "#433940", bold = true })
vim.api.nvim_set_hl(0, "LspDiagnosticsLineNrInfo", { fg = "#569fba", bg = "#2b344a", bold = true })
vim.api.nvim_set_hl(0, "LspDiagnosticsLineNrHint", { fg = "#a3be8c", bg = "#363943", bold = true })
