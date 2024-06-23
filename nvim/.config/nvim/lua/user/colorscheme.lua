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
