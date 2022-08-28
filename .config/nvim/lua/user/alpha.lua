local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

-- TODO use custom header from file
local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
	[[                               __                ]],
	[[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
	[[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
	[[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
	[[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
	[[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
}

dashboard.section.buttons.val = {
	dashboard.button("f", " " .. " Find file", ":Telescope find_files<CR>"),
	dashboard.button("e", " " .. " New file", ":ene <BAR> startinsert <CR>"),
	dashboard.button("p", " " .. " Find project", ":lua require('telescope').extensions.projects.projects()<CR>"),
	dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
	dashboard.button("t", " " .. " Find text", ":Telescope live_grep <CR>"),
	dashboard.button("c", " " .. " Config", ":e ~/.config/nvim/init.lua <CR>"),
	dashboard.button("q", " " .. " Quit", ":qa<CR>"),
}

local function footer()
    -- Below doesn't work as packer_plugins table is empty initally
	-- local plugins_count = #vim.tbl_keys(packer_plugins or {})
	local plugins_count = vim.fn.len(vim.fn.globpath("~/.local/share/nvim/site/pack/packer/start", "*", 0, 1))
	local v = vim.version()
	local datetime = os.date(" %d-%m-%Y   %H:%M:%S")
	local platform = vim.fn.has("win32") == 1 and "" or " Linux"
	return string.format(" %d   v%d.%d.%d %s  %s", plugins_count, v.major, v.minor, v.patch, platform, datetime)
end

dashboard.section.footer.val = footer()
dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true
alpha.setup(dashboard.opts)
