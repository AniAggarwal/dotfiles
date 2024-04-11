local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

local capabilities = lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true

local custom_attach = function(client, bufnr)
	-- Disable so that null-ls' formatting can be used without asking for null-ls or lua_ls each time
	if client.name == "lua_ls" then
		client.server_capabilities.document_formatting = false
	end
end

require("mason").setup()
local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup({
	ensure_installed = {
		"bashls",
		"lua_ls",
		"matlab_ls",
		-- "ocamllsp",
		"pyright",
		"texlab",
	},
})

-- must require neodev before lspconfig
require("neodev").setup()
local lspconfig = require("lspconfig")

mason_lspconfig.setup_handlers({
	-- Default handler
	function(server_name)
		lspconfig[server_name].setup({
			on_attach = custom_attach,
			capabilities = capabilities,
		})
	end,
	-- Custom handler for ocamllsp
	["ocamllsp"] = function()
		lspconfig.ocamllsp.setup({
			on_attach = custom_attach,
			capabilities = capabilities,
			cmd = { "ocamllsp" },
			root_dir = lspconfig.util.root_pattern(
				"*.opam",
				"esy.json",
				"package.json",
				"esy.lock",
				"dune-project",
				"jbuild",
				"jbuild-ignore",
				".git",
				"."
			),
		})
	end,

	-- Custom handler for lua_ls
	["lua_ls"] = function()
		lspconfig.lua_ls.setup({
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
						-- disable lua_ls's formatting to use null-ls' instead
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
		local bundles = {
			vim.fn.glob(
				"/opt/java-dap/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar",
				1
			),
		}
		vim.list_extend(bundles, vim.split(vim.fn.glob("/opt/java-dap/vscode-java-test/server/*.jar", 1), "\n"))
		local config = {
			-- The command that starts the language server
			filetypes = { "java" },
			autostart = true,
			on_attach = mount_commands,
			cmd = {
				"/usr/lib/jvm/java-21-openjdk/bin/java",

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
				jdtls_path .. "/plugins/org.eclipse.equinox.launcher_1.6.700.v20231214-2017.jar",

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
							-- url = os.getenv("HOME")
							-- 	.. "/dotfiles/.config/nvim/language-configs/java/cmsc-420-style.xml",
							url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
						},
					},
					configuration = {
						-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
						-- And search for `interface RuntimeOption`
						-- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
						runtimes = {
							{
								name = "JavaSE-11",
								path = "/usr/lib/jvm/java-11-openjdk/",
							},
							{
								name = "JavaSE-21",
								path = "/usr/lib/jvm/java-21-openjdk/",
							},
						},
					},
				},
			},
			-- Language server `initializationOptions`
			-- You need to extend the `bundles` with paths to jar files
			-- if you want to use additional eclipse.jdt.ls plugins.
			init_options = {
				bundles = bundles,
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

-- TODO: this may be causing issues with some buffers not letting hover work
-- properly
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, {
	border = "rounded",
})

lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
	border = "rounded",
})

require("user.lsp.null-ls")
