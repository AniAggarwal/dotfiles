-- Bare nvim for reading one agent-inbox message: rendered markdown and LaTeX, no editor chrome.
-- Started by `agent-inbox open` as `nvim -u inbox-viewer.lua -R FILE`. q or Esc closes it.

local data = vim.fn.stdpath("data")
local lazy = data .. "/lazy/"
vim.opt.runtimepath = {
	vim.env.VIMRUNTIME,
	data .. "/site",
	lazy .. "nvim-treesitter/runtime",
	lazy .. "render-markdown.nvim",
	lazy .. "nvim-web-devicons",
}
for _, name in ipairs({ "netrw", "netrwPlugin", "gzip", "tarPlugin", "zipPlugin", "tutor_mode_plugin", "spellfile_plugin", "matchit", "matchparen" }) do
	vim.g["loaded_" .. name] = 1
end

local o = vim.opt
o.termguicolors = true
o.number = false
o.relativenumber = false
o.signcolumn = "no"
o.foldcolumn = "0"
o.laststatus = 0
o.showtabline = 0
o.cmdheight = 0
o.ruler = false
o.showmode = false
o.showcmd = false
o.shortmess:append("aIFWsc")
o.fillchars = { eob = " " }
o.wrap = true
o.linebreak = true
o.breakindent = true
o.scrolloff = 3
o.mouse = "a"
o.clipboard = "unnamedplus"
o.swapfile = false
o.spell = false
o.cursorline = false
o.conceallevel = 2
o.concealcursor = "nvc"

-- Colors follow the matugen theme the bar and kitty use.
local palette = {}
local theme = io.open(vim.env.HOME .. "/.config/themes/current/colors-kitty.conf")
if theme then
	for line in theme:lines() do
		local key, value = line:match("^(%S+)%s+(#%x%x%x%x%x%x)")
		if key then
			palette[key] = value
		end
	end
	theme:close()
end
local c = {
	bg = palette.background or "#1e1e2e",
	fg = palette.foreground or "#cdd6f4",
	accent = palette.color11 or "#89b4fa",
	tertiary = palette.color12 or "#cba6f7",
	secondary = palette.color10 or "#a6e3a1",
	muted = palette.color8 or "#7f849c",
	error = palette.color9 or "#f38ba8",
	link = palette.url_color or palette.color12 or "#89dceb",
	selection = palette.selection_background or "#45475a",
}

local function blend(top, bottom, alpha)
	local function channel(hex, i)
		return tonumber(hex:sub(i, i + 1), 16)
	end
	local out = "#"
	for _, i in ipairs({ 2, 4, 6 }) do
		out = out .. string.format("%02x", math.floor(channel(top, i) * alpha + channel(bottom, i) * (1 - alpha) + 0.5))
	end
	return out
end

vim.cmd.colorscheme("default")
local surface = blend(c.fg, c.bg, 0.06)
local hl = function(name, spec)
	vim.api.nvim_set_hl(0, name, spec)
end
hl("Normal", { fg = c.fg })
hl("NormalNC", { fg = c.fg })
hl("NonText", { fg = c.muted })
hl("EndOfBuffer", { fg = c.bg })
hl("Visual", { bg = c.selection })
hl("Search", { bg = c.selection })
hl("InboxMeta", { fg = c.muted })
hl("InboxUrgent", { fg = c.error, bold = true })
local headings = { c.accent, c.tertiary, c.secondary, c.fg, c.fg, c.muted }
for level, color in ipairs(headings) do
	hl("@markup.heading." .. level .. ".markdown", { fg = color, bold = true })
	hl("RenderMarkdownH" .. level, { fg = color, bold = true })
	hl("RenderMarkdownH" .. level .. "Bg", { bg = blend(color, c.bg, level <= 2 and 0.16 or 0.08), fg = color, bold = true })
end
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })
hl("@markup.strikethrough", { strikethrough = true })
hl("@markup.raw", { fg = c.tertiary })
hl("@markup.raw.block", { fg = c.fg })
hl("@markup.link", { fg = c.link })
hl("@markup.link.label", { fg = c.link })
hl("@markup.link.url", { fg = c.link, underline = true })
hl("@markup.quote", { fg = c.secondary, italic = true })
hl("@markup.list", { fg = c.accent })
hl("RenderMarkdownCode", { bg = surface })
hl("RenderMarkdownCodeInline", { bg = surface, fg = c.tertiary })
hl("RenderMarkdownMath", { fg = c.tertiary })
hl("RenderMarkdownBullet", { fg = c.accent })
hl("RenderMarkdownQuote", { fg = c.muted })
hl("RenderMarkdownDash", { fg = c.muted })
hl("RenderMarkdownTableHead", { fg = c.muted })
hl("RenderMarkdownTableRow", { fg = c.muted })
hl("RenderMarkdownLink", { fg = c.link })
hl("RenderMarkdownUnchecked", { fg = c.muted })
hl("RenderMarkdownChecked", { fg = c.accent })

require("render-markdown").setup({
	render_modes = true,
	anti_conceal = { enabled = false },
	heading = { sign = false, width = "full", left_pad = 1 },
	code = { sign = false, width = "block", left_pad = 2, right_pad = 2, border = "thick" },
	pipe_table = { preset = "round", cell = "padded" },
	latex = { enabled = true, converter = { "utftex", "latex2text" }, highlight = "RenderMarkdownMath" },
	html = { comment = { conceal = false } },
})

-- Replace the raw file with a scratch buffer: title as a heading, sender details under it, then the body.
local function show(path)
	local lines = vim.fn.readfile(path)
	local meta, body = {}, lines
	if lines[1] == "---" then
		for i = 2, #lines do
			if lines[i] == "---" then
				body = vim.list_slice(lines, i + 1)
				break
			end
			local key, value = lines[i]:match("^([%w_]+): (.*)$")
			if key then
				local ok, decoded = pcall(vim.json.decode, value)
				meta[key] = ok and decoded or value
			end
		end
	end

	local sent = ""
	if type(meta.sent) == "string" then
		local y, m, d, hh, mm = meta.sent:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
		if y then
			local time = os.time({ year = y, month = m, day = d, hour = hh, min = mm })
			sent = os.date(os.date("%Y-%m-%d") == string.format("%s-%s-%s", y, m, d) and "%H:%M" or "%a %b %-d, %H:%M", time)
		end
	end
	local where = meta.project and (meta.project .. (meta.branch and meta.branch ~= "" and (" on " .. meta.branch) or "")) or nil
	local details = vim.tbl_filter(function(part)
		return part and part ~= ""
	end, { meta.from, where, sent })

	local content = { "# " .. (meta.title or vim.fn.fnamemodify(path, ":t:r")), "" }
	-- render-markdown can only replace single-line math blocks, so fold multi-line $$ blocks into one line.
	local math
	for _, line in ipairs(body) do
		if vim.trim(line) == "$$" then
			if math then
				table.insert(content, "$$ " .. table.concat(math, " ") .. " $$")
				math = nil
			else
				math = {}
			end
		elseif math then
			table.insert(math, vim.trim(line))
		else
			table.insert(content, line)
		end
	end
	if math then
		vim.list_extend(content, { "$$", unpack(math) })
	end
	while #content > 2 and content[#content] == "" do
		table.remove(content)
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.api.nvim_set_current_buf(buf)
	vim.bo[buf].filetype = "markdown"
	pcall(vim.treesitter.start, buf, "markdown")

	local virt = { { table.concat(details, ", "), "InboxMeta" } }
	if meta.urgent == true then
		table.insert(virt, 1, { "Urgent  ", "InboxUrgent" })
	end
	vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace("agent-inbox"), 0, 0, { virt_lines = { virt } })

	for _, key in ipairs({ "q", "<Esc>", "<C-c>" }) do
		vim.keymap.set("n", key, "<Cmd>qa!<CR>", { buffer = buf, nowait = true })
	end
	vim.wo.wrap = true
	vim.wo.linebreak = true
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local path = vim.fn.argv(0)
		if type(path) == "string" and path ~= "" then
			local original = vim.api.nvim_get_current_buf()
			show(vim.fn.fnamemodify(path, ":p"))
			pcall(vim.api.nvim_buf_delete, original, { force = true })
		end
	end,
})
