return {

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate", -- Automatically update parsers on install/update
		event = { "BufReadPost", "BufNewFile" }, -- Lazy load treesitter when opening a file
		opts = {
			ensure_installed = { "python", "c", "lua", "bash" }, -- List of languages to install
			auto_install = true,
			ignore_install = { "latex" }, -- Parsers to ignore
			highlight = {
				enable = true,
				disable = { "latex" }, -- Languages for which highlighting is disabled
			},
			autopairs = {
				enable = true, -- Enable autopairs integration
			},
			indent = {
				enable = true,
				disable = { "python", "latex" }, -- Disable indent for these languages
			},
		},
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = "BufReadPost",
		dependencies = { "nvim-treesitter/nvim-treesitter" }, -- Ensure nvim-treesitter is loaded first
	},

	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		event = { "BufReadPre", "BufNewFile", "BufEnter", "FileType" },
		opts = {
			ensure_installed = {
				"basedpyright",
				"bashls",
				"lua_ls",
				"texlab",
			},
		},
		config = function(_, opts)
			require("mason").setup() -- must be called before using mason_lspconfig
			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup(opts)

			local lspconfig = require("lspconfig")

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

			-- TODO: does this fix HTML render issues in hugginface docs?
			capabilities.textDocument.hover = {
				contentFormat = { "markdown", "plaintext", "html" },
			}

			-- TODO: investigate if this true setting is needed
			-- capabilities.textDocument.completion.completionItem.snippetSupport = true

			-- Can define a custom_attach and pass into setup just as the custom capabilities is passed in
			-- local custom_attach = function(client, bufnr) -- do something end

			mason_lspconfig.setup_handlers({
				-- Default handler
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end,

				["basedpyright"] = function()
					lspconfig.basedpyright.setup({
						capabilities = capabilities,
						settings = {
							python = {
								analysis = {
									typeCheckingMode = "basic",
									diagnosticSeverityOverrides = {
										reportUnknownArgumentType = "warning",
									},
								},
							},
						},
					})
				end,

				["clangd"] = function()
					lspconfig.clangd.setup({
						-- capabilities but with offsetEncoding utf-16
						capabilities = vim.tbl_deep_extend("force", capabilities, { offsetEncoding = { "utf-16" } }),
					})
				end,

				-- -- Custom handler for ocamllsp
				-- ["ocamllsp"] = function()
				--     lspconfig.ocamllsp.setup({
				--         on_attach = custom_attach,
				--         capabilities = capabilities,
				--         cmd = { "ocamllsp" },
				--         root_dir = lspconfig.util.root_pattern(
				--             "*.opam",
				--             "esy.json",
				--             "package.json",
				--             "esy.lock",
				--             "dune-project",
				--             "jbuild",
				--             "jbuild-ignore",
				--             ".git",
				--             "."
				--         ),
				--     })
				-- end,
				--
				-- Custom handler for lua_ls
				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
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
					vim.list_extend(
						bundles,
						vim.split(vim.fn.glob("/opt/java-dap/vscode-java-test/server/*.jar", 1), "\n")
					)
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
							jdtls_path .. "/plugins/org.eclipse.equinox.launcher_1.6.900.v20240613-2009.jar",

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
		end,
	},

	-- Language specific

	-- clangd_extensions setup for C/C++ files
	{
		"p00f/clangd_extensions.nvim",
		ft = { "c", "cpp", "objc", "objcpp" },
	},

	-- nvim-jdtls setup for Java files
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
	},

	{
		"lervag/vimtex",
		ft = { "tex" },
		config = function()
			vim.api.nvim_command("filetype plugin indent on")
			vim.api.nvim_command("syntax enable")

			vim.g.vimtex_view_method = "zathura"

			vim.g.vimtex_quickfix_mode = 0 -- Disable quickfix mode

			-- Auto Indent and Syntax Highlighting
			vim.g.vimtex_indent_enabled = 0 -- Disable auto-indent
			vim.g.vimtex_syntax_enabled = 1 -- Enable syntax highlighting
		end,
	},
}
