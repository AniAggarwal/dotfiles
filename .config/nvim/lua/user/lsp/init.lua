local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

local custom_attach = function(client, bufnr)
	-- Keymappings
    -- TODO move all this to whichkey
	local keymap_opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, keymap_opts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, keymap_opts)
	vim.keymap.set("n", "gI", vim.lsp.buf.implementation, keymap_opts)
	vim.keymap.set("n", "gl", vim.diagnostic.open_float, keymap_opts)
	vim.keymap.set("n", "]g", vim.diagnostic.goto_next, { noremap = true, silent = true, buffer = 0 })
	vim.keymap.set("n", "[g", vim.diagnostic.goto_prev, { noremap = true, silent = true, buffer = 0 })
	vim.keymap.set("n", "gf", vim.lsp.buf.formatting, keymap_opts)
	vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, keymap_opts)
	vim.keymap.set("n", "ga", vim.lsp.buf.code_action, keymap_opts)
	vim.keymap.set("n", "gn", vim.lsp.buf.rename, keymap_opts)


    -- Dispable so that null-ls' formatting can be used without asking for null-ls or sumneko_lua each time
	if client.name == "sumneko_lua" then
		client.resolved_capabilities.document_formatting = false
	end

end

local capabilities = lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true

require("mason").setup()

local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")

mason_lspconfig.setup()
mason_lspconfig.setup_handlers({
	-- Default handler
	function(server_name)
		lspconfig[server_name].setup({
			on_attach = custom_attach,
			capabilities = capabilities,
		})
	end,

	-- Custom handler for sumneko_lua
	["sumneko_lua"] = function()
		lspconfig.sumneko_lua.setup({
			on_attach = custom_attach,
			capabilities = capabilities,

			settings = {
				Lua = {
					-- Tells lua that vim and use exist for nvim configuration
					diagnostics = {
						globals = { "vim", "use" },
					},
					workspace = {
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
                    format = {
                        -- disable sumneko_lua's formatting to use null-ls' instead
                        enable = false,
                    }
				},
			},
		})
	end,

    -- TODO set up jdtls
	["jdtls"] = function()
		local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = os.getenv("HOME") .. "/.cache/jdtls/workspace/" .. project_name
		local mount_commands = function()
			local jdtls = require("jdtls")

            -- TODO customize keymaps
			-- Set some keymaps for extra functionality
			vim.keymap.set("n", "<A-o>", function()
				jdtls.organize_imports()
			end)
			vim.keymap.set("n", "crv", function()
				jdtls.extract_variable()
			end)
			vim.keymap.set("v", "crv", function()
				jdtls.extract_variable(true)
			end)
			vim.keymap.set("n", "crc", function()
				jdtls.extract_variable()
			end)
			vim.keymap.set("v", "crc", function()
				jdtls.extract_variable(true)
			end)
			vim.keymap.set("v", "crm", function()
				jdtls.extract_method(true)
			end)

            custom_attach() -- add other custom keymaps, TODO remove just this line after using whichkey

			require("jdtls.setup").add_commands()
		end
		local config = {
			-- The command that starts the language server
			filetypes = { "java" },
			autostart = true,
			on_attach = mount_commands,
			cmd = {

				"java",

				"-Declipse.application=org.eclipse.jdt.ls.core.id1",
				"-Dosgi.bundles.defaultStartLevel=4",
				"-Declipse.product=org.eclipse.jdt.ls.core.product",
				"-Dlog.protocol=true",
				"-Dlog.level=ALL",
				"-Xms1g",
				"--add-modules=ALL-SYSTEM",
				"--add-opens",
				"java.base/java.util=ALL-UNNAMED",
				"--add-opens",
				"java.base/java.lang=ALL-UNNAMED",

				"-jar",
				jdtls_path .. "/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar",

				"-configuration",
				jdtls_path .. "/config_linux",

				"-data",
				workspace_dir,
			},

			root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),

			-- Here you can configure eclipse.jdt.ls specific settings
			settings = {
				java = {},
			},

			-- Language server `initializationOptions`
			-- You need to extend the `bundles` with paths to jar files
			-- if you want to use additional eclipse.jdt.ls plugins.
			init_options = {
				bundles = {
					"/home/owhan/projects/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.40.0.jar",
				},
			},
		}

		-- Create autocmd for launching jdtls on java filetype, similar to lspconfig implementation
		local lsp_group = vim.api.nvim_create_augroup("lspconfig", { clear = false })
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "java",
			callback = function()
				require("jdtls").start_or_attach(config)
			end,
			group = lsp_group,
			desc = "Checks whether server jdtls should start a new instance or attach to an existing one.",
		})
	end,
})

-- Change diagnostic signs.
fn.sign_define("DiagnosticSignError", { numhl = "LspDiagnosticsLineNrError" })
fn.sign_define("DiagnosticSignWarn", { numhl = "LspDiagnosticsLineNrWarning" })
fn.sign_define("DiagnosticSignInformation", { numhl = "LspDiagnosticsLineNrInfo" })
fn.sign_define("DiagnosticSignHint", { numhl = "LspDiagnosticsLineNrHint" })
vim.cmd("highlight LspDiagnosticsLineNrError guifg=#eb6f92 guibg=#412d44 gui=bold")
vim.cmd("highlight LspDiagnosticsLineNrWarning guifg=#f6c177 guibg=#433940 gui=bold")
vim.cmd("highlight LspDiagnosticsLineNrInfo guifg=#569fba guibg=#2b344a gui=bold")
vim.cmd("highlight LspDiagnosticsLineNrHint guifg=#a3be8c guibg=#363943 gui=bold")

-- global config for diagnostic
vim.diagnostic.config({
	virtual_text = false,
	underline = false,
	signs = true,
	severity_sort = true,
	float = {
		focusable = true,
		style = "minimal",
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
	},
})

lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, {
	border = "rounded",
})

lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
	border = "rounded",
})


require("user.lsp.null-ls")
