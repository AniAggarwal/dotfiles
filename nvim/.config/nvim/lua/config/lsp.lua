vim.diagnostic.config({
    virtual_text = false,
    underline = false,
    severity_sort = true,
    float = {
        focusable = true,
        style = "minimal",
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "LspDiagnosticsLineNrError",
            [vim.diagnostic.severity.WARN] = "LspDiagnosticsLineNrWarning",
            [vim.diagnostic.severity.INFO] = "LspDiagnosticsLineNrInfo",
            [vim.diagnostic.severity.HINT] = "LspDiagnosticsLineNrHint",
        },
    },
})


-- Custom hover function for neovim 0.11+
-- vim.lsp.handlers["textDocument/hover"] no longer works in 0.11 (breaking change)
-- Instead, we create a custom hover function that processes the response
local function strip_markdown_escapes(contents)
	if type(contents) == "string" then
		return contents:gsub("\\([_*`])", "%1")
	elseif type(contents) == "table" then
		if contents.value then
			contents.value = contents.value:gsub("\\([_*`])", "%1")
		elseif contents.kind then
			-- MarkupContent without value field, skip
		else
			-- Array of contents
			for i, item in ipairs(contents) do
				contents[i] = strip_markdown_escapes(item)
			end
		end
	end
	return contents
end

-- Custom hover that strips escape sequences before display
function _G.custom_hover()
	-- Get the first LSP client that supports hover
	local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/hover" })
	if #clients == 0 then
		vim.notify("No LSP client with hover support", vim.log.levels.WARN)
		return
	end
	local client = clients[1]
	local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
	client:request("textDocument/hover", params, function(err, result, ctx)
		if err then
			vim.notify("Hover error: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end
		if not result or not result.contents then
			vim.notify("No information available", vim.log.levels.INFO)
			return
		end
		-- Strip markdown escapes
		result.contents = strip_markdown_escapes(result.contents)
		-- Display using the standard hover handler
		local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
		if vim.tbl_isempty(lines) then
			vim.notify("No information available", vim.log.levels.INFO)
			return
		end
		vim.lsp.util.open_floating_preview(lines, "markdown", {
			border = "rounded",
			focus = false,
		})
	end)
end

-- Override K to use our custom hover
vim.keymap.set("n", "K", _G.custom_hover, { desc = "LSP Hover (with escape fix)" })

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = "rounded",
    focus = false
})

-- Simple code action lightbulb indicator (no plugin, no deprecation warnings)
-- Uses extmarks instead of deprecated sign_define
local lightbulb_ns = vim.api.nvim_create_namespace("code_action_lightbulb")
local lightbulb_icon = ""

local function update_lightbulb()
	vim.api.nvim_buf_clear_namespace(0, lightbulb_ns, 0, -1)
	local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/codeAction" })
	if #clients == 0 then return end

	local client = clients[1]
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
	params.context = { diagnostics = vim.diagnostic.get(0, { lnum = line }) }

	client:request("textDocument/codeAction", params, function(err, result)
		if err or not result or vim.tbl_isempty(result) then return end
		-- Show lightbulb on current line using extmark
		local line = vim.api.nvim_win_get_cursor(0)[1] - 1
		pcall(vim.api.nvim_buf_set_extmark, 0, lightbulb_ns, line, 0, {
			virt_text = { { lightbulb_icon, "DiagnosticSignHint" } },
			virt_text_pos = "eol",
			hl_mode = "combine",
		})
	end)
end

vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
	group = vim.api.nvim_create_augroup("LightbulbUpdate", { clear = true }),
	callback = update_lightbulb,
})
