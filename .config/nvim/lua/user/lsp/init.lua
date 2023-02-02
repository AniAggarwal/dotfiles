local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

local capabilities = lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- local clangd_capabilities = capabilities
-- clangd_capabilities.textDocument.semanticHighlighting = true
-- Doesn't seem neccesary or isn't doing anything
-- clangd_capabilities.offsetEncoding = {"utf-16"}
-- clangd_capabilities.offset_encoding = "utf-16"
-- print(vim.inspect(clangd_capabilities))


local custom_attach = function(client, bufnr)
	-- Disable so that null-ls' formatting can be used without asking for null-ls or sumneko_lua each time
	if client.name == "sumneko_lua" then
		client.server_capabilities.document_formatting = false
	end
end


require("mason").setup()
local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup()

local lspconfig = require("lspconfig")

mason_lspconfig.setup_handlers({
	-- Default handler
	function(server_name)
		lspconfig[server_name].setup({
			on_attach = custom_attach,
			capabilities = capabilities,
		})
	end,

	-- ["clangd"] = function()
	-- 	lspconfig.clangd.setup({
	-- 		cmd = { "clangd" , "--offset-encoding=utf-16" },
	-- 		on_attach = custom_attach,
	-- 		capabilities = capabilities,
	-- 	})
	-- end,

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
					},
				},
			},
		})
	end,

	["jdtls"] = function()
		local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = os.getenv("HOME") .. "/.cache/jdtls/workspace/" .. project_name
		local mount_commands = function()
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
				java = {
					format = {
						settings = {
							url = os.getenv("HOME")
								.. "/dotfiles/.config/nvim/language-configs/java/cmsc-132-style.xml",
						},
					},
				},
			},

			-- Language server `initializationOptions`
			-- You need to extend the `bundles` with paths to jar files
			-- if you want to use additional eclipse.jdt.ls plugins.
			init_options = {
				bundles = {
					-- TODO: add my own path
					-- "/home/owhan/projects/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.40.0.jar",
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
			desc = "Checks if LSP jdtls should start a new instance or attach an existing one.",
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
