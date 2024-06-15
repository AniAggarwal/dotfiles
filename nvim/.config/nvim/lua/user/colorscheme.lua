local palette = require("onedark.palette").dark

require("onedark").setup({
	style = "dark",
	colors = {
		bg = palette.bg0,
		bg2 = palette.bg1,
		fg = palette.fg,
		blue = palette.blue,
	},
	highlights = {
		-- ["@variable"] = { fg = palette.red },
		Pmenu = { fg = "$fg", bg = "$bg2" },
		PmenuSel = { fg = "$bg2", bg = "$blue" },
		CmpItemMenu = { fg = "$fg", bg = "$bg2" },
		NormalFloat = { bg = "$bg" }, -- Match the background of the floating window to the main background
		FloatBorder = { bg = "$bg", fg = "$fg" }, -- Keep the border but match the background to the main background
	},
})

require("onedark").load()

-- require("onedark").setup({
-- 	style = "dark",
-- 	colors = {
-- 		bg = "#282c34",
-- 		fg = "#abb2bf",
-- 		yellow = "#e5c07b",
-- 		cyan = "#56b6c2",
-- 		darkblue = "#081633",
-- 		green = "#98c379",
-- 		orange = "#d19a66",
-- 		violet = "#c678dd",
-- 		magenta = "#e06c75",
-- 		blue = "#61afef",
-- 		red = "#e06c75",
-- 	},
-- 	highlights = {
-- 		Normal = { fg = "#abb2bf", bg = "#282c34" },
-- 		NormalFloat = { fg = "#abb2bf", bg = "#081633" },
-- 		Comment = { fg = "#98c379", style = "italic" },
-- 		Constant = { fg = "#56b6c2" },
-- 		Identifier = { fg = "#61afef" },
-- 		Statement = { fg = "#e06c75" },
-- 		PreProc = { fg = "#c678dd" },
-- 		Type = { fg = "#e5c07b" },
-- 		Special = { fg = "#d19a66" },
-- 		Underlined = { style = "underline" },
-- 		Todo = { fg = "#c678dd", bg = "#282c34", style = "bold" },
-- 		String = { fg = "#98c379" },
-- 		Function = { fg = "#61afef" },
-- 		Conditional = { fg = "#e06c75" },
-- 		Repeat = { fg = "#e06c75" },
-- 		Operator = { fg = "#56b6c2" },
-- 		Structure = { fg = "#c678dd" },
-- 		LineNr = { fg = "#abb2bf" },
-- 		CursorLineNr = { fg = "#e5c07b" },
-- 		SpecialKey = { fg = "#61afef" },
-- 		NonText = { fg = "#61afef" },
-- 		MatchParen = { fg = "#e06c75", style = "bold" },
-- 		Pmenu = { fg = "#abb2bf", bg = "#081633" },
-- 		PmenuSel = { fg = "#282c34", bg = "#61afef" },
-- 		Visual = { bg = "#081633" },
-- 		VisualNOS = { bg = "#081633" },
-- 		Search = { fg = "#282c34", bg = "#e5c07b" },
-- 		IncSearch = { fg = "#282c34", bg = "#d19a66" },
-- 		Directory = { fg = "#61afef" },
-- 		ErrorMsg = { fg = "#e06c75", bg = "#282c34", style = "bold" },
-- 		WarningMsg = { fg = "#e5c07b", bg = "#282c34", style = "bold" },
-- 		MoreMsg = { fg = "#61afef", bg = "#282c34", style = "bold" },
-- 		ModeMsg = { fg = "#61afef", bg = "#282c34", style = "bold" },
-- 		StatusLine = { fg = "#abb2bf", bg = "#282c34" },
-- 		StatusLineNC = { fg = "#abb2bf", bg = "#282c34" },
-- 		VertSplit = { fg = "#282c34", bg = "#282c34" },
-- 		Title = { fg = "#98c379", style = "bold" },
-- 		SpecialChar = { fg = "#e06c75" },
-- 		Tag = { fg = "#d19a66" },
-- 		Delimiter = { fg = "#abb2bf" },
-- 		SpecialComment = { fg = "#98c379", style = "italic" },
-- 		Debug = { fg = "#e06c75" },
-- 		Folded = { fg = "#abb2bf", bg = "#282c34" },
-- 		FoldColumn = { fg = "#abb2bf", bg = "#282c34" },
-- 		SignColumn = { fg = "#abb2bf", bg = "#282c34" },
-- 		Conceal = { fg = "#61afef", bg = "#282c34" },
-- 		SpellBad = { fg = "#e06c75", style = "underline" },
-- 		SpellCap = { fg = "#61afef", style = "underline" },
-- 		SpellLocal = { fg = "#56b6c2", style = "underline" },
-- 		SpellRare = { fg = "#c678dd", style = "underline" },
-- 		TabLine = { fg = "#abb2bf", bg = "#282c34" },
-- 		TabLineSel = { fg = "#282c34", bg = "#61afef" },
-- 		TabLineFill = { fg = "#abb2bf", bg = "#282c34" },
-- 	},
-- })
--
-- require("onedark").load()
