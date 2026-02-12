return {

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate", -- Automatically update parsers on install/update
		-- event = { "BufReadPost", "BufNewFile" }, -- Lazy load treesitter when opening a file
		lazy = false, -- doesn't work w lazy loading
		branch = "master",
		opts = {
			ensure_installed = { "python", "c", "lua", "bash", "markdown", "markdown_inline" }, -- List of languages to install
			auto_install = true,
			ignore_install = {}, -- Parsers to ignore
			highlight = {
				enable = true,
				disable = { "latex" }, -- Languages for which highlighting is disabled
			},
			autopairs = {
				enable = true, -- Enable autopairs integration
			},
			indent = {
				enable = true,
				disable = { "python" }, -- Disable indent for these languages
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
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
		event = { "BufReadPre", "BufNewFile", "BufEnter", "FileType" },
		opts = {
			ensure_installed = { "basedpyright", "ty", "ruff", "clangd", "jdtls", "bashls", "lua_ls", "texlab" },
			-- Let mason-lspconfig auto-enable all except jdtls (we handle jdtls ourselves)
			automatic_enable = { exclude = { "jdtls" } },
		},
		config = function(_, opts)
			require("mason").setup()

			-- Default LSP config (applies to all mason-enabled servers)
			local capabilities =
				require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
			capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

			vim.lsp.config("*", { capabilities = capabilities })

			-- basedpyright (LSP features only: hover, go-to-def, completions, references)
			-- Type checking handled by ty, linting/formatting by ruff
			vim.lsp.config("basedpyright", {
				capabilities = capabilities,
				settings = {
					basedpyright = {
						disableOrganizeImports = true,
						analysis = {
							typeCheckingMode = "off",
						},
					},
				},
			})

			-- ty (type checking, strict mode)
			vim.lsp.config("ty", {
				capabilities = capabilities,
				settings = {
					ty = {
						-- Using defaults with strict checking
					},
				},
			})

			-- ruff (linting + formatting, replaces black/isort/flake8)
			vim.lsp.config("ruff", {
				capabilities = capabilities,
				init_options = {
					settings = {
						lineLength = 79,
						lint = {
							select = {
								"E", -- pycodestyle errors (PEP8)
								"W", -- pycodestyle warnings (PEP8)
								"F", -- pyflakes
								"I", -- isort
								"N", -- pep8-naming (variable/function naming conventions)
								"UP", -- pyupgrade
								"B", -- flake8-bugbear
								"C4", -- flake8-comprehensions
								"SIM", -- flake8-simplify
							},
							-- Migrated from .flake8 extend-ignore
							ignore = { "E402", "E501", "E203", "E731" },
						},
					},
				},
			})

			-- Disable hover/definition for ruff and ty, let basedpyright handle it
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_attach_disable_duplicate_providers", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and (client.name == "ruff" or client.name == "ty") then
						client.server_capabilities.hoverProvider = false
						client.server_capabilities.definitionProvider = false
					end
				end,
				desc = "Disable ruff/ty hover/definition in favor of basedpyright",
			})

			-- clangd: utf-16 offsets
			vim.lsp.config("clangd", {
				capabilities = vim.tbl_deep_extend("force", capabilities, { offsetEncoding = { "utf-16" } }),
			})

			-- lua_ls
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = { globals = { "vim", "use" } },
						workspace = {
							library = {
								[vim.fn.expand("$VIMRUNTIME/lua")] = true,
								[vim.fn.stdpath("config") .. "/lua"] = true,
							},
						},
						format = { enable = false },
					},
				},
			})

			-- Install + auto-enable (uses the configs above)
			require("mason-lspconfig").setup(opts)

			-- ===== jdtls (manual) =====
			local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
			local function jdtls_start()
				local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
				local workspace_dir = vim.env.HOME .. "/.cache/jdtls/workspace/" .. project_name
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
					settings = {
						java = {
							format = {
								settings = {
									url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
								},
							},
							configuration = {
								runtimes = {
									{ name = "JavaSE-11", path = "/usr/lib/jvm/java-11-openjdk/" },
									{ name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk/" },
								},
							},
						},
					},
					init_options = { bundles = bundles },
				}
				require("jdtls").start_or_attach(config)
			end

			local lsp_group = vim.api.nvim_create_augroup("lspconfig", { clear = false })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = jdtls_start,
				group = lsp_group,
				desc = "Start or attach jdtls",
			})
		end,
	},
	-- {
	-- 	"williamboman/mason-lspconfig.nvim",
	-- 	dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
	-- 	event = { "BufReadPre", "BufNewFile", "BufEnter", "FileType" },
	-- 	opts = {
	-- 		ensure_installed = {
	-- 			"basedpyright",
	-- 			"clangd",
	-- 			"jdtls",
	-- 			"bashls",
	-- 			"lua_ls",
	-- 			"texlab",
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("mason").setup() -- must be called before using mason_lspconfig
	-- 		local mason_lspconfig = require("mason-lspconfig")
	-- 		mason_lspconfig.setup(opts)
	--
	-- 		local lspconfig = require("lspconfig")
	--
	-- 		local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- 		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
	-- 		-- TODO: investigate if this true setting is needed
	-- 		-- capabilities.textDocument.completion.completionItem.snippetSupport = true
	--
	-- 		capabilities.textDocument.foldingRange = {
	-- 			dynamicRegistration = false,
	-- 			lineFoldingOnly = true,
	-- 		}
	--
	-- 		-- Can define a custom_attach and pass into setup just as the custom capabilities is passed in
	-- 		-- local custom_attach = function(client, bufnr) -- do something end
	--
	-- 		mason_lspconfig.setup_handlers({
	-- 			-- Default handler
	-- 			function(server_name)
	-- 				lspconfig[server_name].setup({
	-- 					capabilities = capabilities,
	-- 				})
	-- 			end,
	--
	-- 			-- TODO: enable these later
	-- 			["basedpyright"] = function()
	-- 				lspconfig.basedpyright.setup({
	-- 					capabilities = capabilities,
	-- 					settings = {
	-- 						basedpyright = {
	-- 							analysis = {
	-- 								typeCheckingMode = "basic",
	-- 								diagnosticSeverityOverrides = {
	-- 									reportUnknownArgumentType = "warning",
	-- 								},
	-- 							},
	-- 						},
	-- 					},
	-- 				})
	-- 			end,
	--
	-- 			["clangd"] = function()
	-- 				lspconfig.clangd.setup({
	-- 					-- capabilities but with offsetEncoding utf-16
	-- 					capabilities = vim.tbl_deep_extend("force", capabilities, { offsetEncoding = { "utf-16" } }),
	-- 				})
	-- 			end,
	--
	-- 			-- -- Custom handler for ocamllsp
	-- 			-- ["ocamllsp"] = function()
	-- 			--     lspconfig.ocamllsp.setup({
	-- 			--         on_attach = custom_attach,
	-- 			--         capabilities = capabilities,
	-- 			--         cmd = { "ocamllsp" },
	-- 			--         root_dir = lspconfig.util.root_pattern(
	-- 			--             "*.opam",
	-- 			--             "esy.json",
	-- 			--             "package.json",
	-- 			--             "esy.lock",
	-- 			--             "dune-project",
	-- 			--             "jbuild",
	-- 			--             "jbuild-ignore",
	-- 			--             ".git",
	-- 			--             "."
	-- 			--         ),
	-- 			--     })
	-- 			-- end,
	-- 			--
	-- 			-- Custom handler for lua_ls
	-- 			["lua_ls"] = function()
	-- 				lspconfig.lua_ls.setup({
	-- 					capabilities = capabilities,
	-- 					settings = {
	-- 						Lua = {
	-- 							-- Tells lua that vim and use exist for nvim configuration
	-- 							diagnostics = {
	-- 								globals = { "vim", "use" },
	-- 							},
	-- 							workspace = {
	-- 								library = {
	-- 									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
	-- 									[vim.fn.stdpath("config") .. "/lua"] = true,
	-- 								},
	-- 							},
	-- 							format = {
	-- 								-- disable lua_ls's formatting to use null-ls' instead
	-- 								enable = false,
	-- 							},
	-- 						},
	-- 					},
	-- 				})
	-- 			end,
	-- 			["jdtls"] = function()
	-- 				local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
	-- 				local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
	-- 				local workspace_dir = os.getenv("HOME") .. "/.cache/jdtls/workspace/" .. project_name
	-- 				local mount_commands = function()
	-- 					require("jdtls.setup").add_commands()
	-- 				end
	-- 				local bundles = {
	-- 					vim.fn.glob(
	-- 						"/opt/java-dap/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar",
	-- 						1
	-- 					),
	-- 				}
	-- 				vim.list_extend(
	-- 					bundles,
	-- 					vim.split(vim.fn.glob("/opt/java-dap/vscode-java-test/server/*.jar", 1), "\n")
	-- 				)
	-- 				local config = {
	-- 					-- The command that starts the language server
	-- 					filetypes = { "java" },
	-- 					autostart = true,
	-- 					on_attach = mount_commands,
	-- 					cmd = {
	-- 						"/usr/lib/jvm/java-21-openjdk/bin/java",
	--
	-- 						"-Declipse.application=org.eclipse.jdt.ls.core.id1",
	-- 						"-Dosgi.bundles.defaultStartLevel=4",
	-- 						"-Declipse.product=org.eclipse.jdt.ls.core.product",
	-- 						"-Dlog.protocol=true",
	-- 						"-Dlog.level=ALL",
	-- 						"-Xms1g",
	-- 						"--add-modules=ALL-SYSTEM",
	-- 						"--add-opens",
	-- 						"java.base/java.util=ALL-UNNAMED",
	-- 						"--add-opens",
	-- 						"java.base/java.lang=ALL-UNNAMED",
	--
	-- 						"-jar",
	-- 						jdtls_path .. "/plugins/org.eclipse.equinox.launcher_1.6.900.v20240613-2009.jar",
	--
	-- 						"-configuration",
	-- 						jdtls_path .. "/config_linux",
	--
	-- 						"-data",
	-- 						workspace_dir,
	-- 					},
	-- 					root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),
	-- 					-- Here you can configure eclipse.jdt.ls specific settings
	-- 					settings = {
	-- 						java = {
	-- 							format = {
	-- 								settings = {
	-- 									-- url = os.getenv("HOME")
	-- 									-- 	.. "/dotfiles/.config/nvim/language-configs/java/cmsc-420-style.xml",
	-- 									url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
	-- 								},
	-- 							},
	-- 							configuration = {
	-- 								-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
	-- 								-- And search for `interface RuntimeOption`
	-- 								-- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
	-- 								runtimes = {
	-- 									{
	-- 										name = "JavaSE-11",
	-- 										path = "/usr/lib/jvm/java-11-openjdk/",
	-- 									},
	-- 									{
	-- 										name = "JavaSE-21",
	-- 										path = "/usr/lib/jvm/java-21-openjdk/",
	-- 									},
	-- 								},
	-- 							},
	-- 						},
	-- 					},
	-- 					-- Language server `initializationOptions`
	-- 					-- You need to extend the `bundles` with paths to jar files
	-- 					-- if you want to use additional eclipse.jdt.ls plugins.
	-- 					init_options = {
	-- 						bundles = bundles,
	-- 					},
	-- 				}
	--
	-- 				-- Create autocmd for launching jdtls on java filetype, similar to lspconfig implementation
	-- 				local lsp_group = vim.api.nvim_create_augroup("lspconfig", { clear = false })
	-- 				vim.api.nvim_create_autocmd("FileType", {
	-- 					pattern = "java",
	-- 					callback = function()
	-- 						require("jdtls").start_or_attach(config)
	-- 					end,
	-- 					group = lsp_group,
	-- 					desc = "Checks if LSP jdtls should start a new instance or attach an existing one.",
	-- 				})
	-- 			end,
	-- 		})
	-- 	end,
	-- },

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
		lazy = false, -- inverse search doesn't work with lazy
		ft = { "tex" },
		config = function()
			vim.api.nvim_command("filetype plugin indent on")
			vim.api.nvim_command("syntax enable")

			vim.g.vimtex_view_method = "zathura"

			vim.g.vimtex_quickfix_mode = 0 -- Disable quickfix mode

			-- Auto Indent and Syntax Highlighting
			vim.g.vimtex_indent_enabled = 0 -- Disable auto-indent
			vim.g.vimtex_syntax_enabled = 1 -- Enable syntax highlighting

			-- Use lualatex as the default engine
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_compiler_latexmk_engines = {
				_ = "-lualatex",
			}
		end,
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			pipe_table = {
				preset = "round",
				cell = "padded",
				-- -- Compensate for emphasis markers that get concealed
				-- -- Each ** or * pair loses characters when concealed
				-- cell_offset = function(ctx)
				-- 	local text = vim.treesitter.get_node_text(ctx.node, 0)
				-- 	-- Count emphasis markers: ** (bold) and * (italic)
				-- 	local bold_count = select(2, text:gsub("%*%*", "")) * 2
				-- 	local italic_count = select(2, text:gsub("%*", "")) - (bold_count)
				-- 	return bold_count + italic_count
				-- end,
			},
			latex = {
				enabled = true,
				converter = "latex2text", -- or "utftex"
				highlight = "RenderMarkdownMath",
			},
			html = {
				comment = {
					conceal = false,
				},
			},
		},
	},
	{
		"epwalsh/obsidian.nvim",
		version = "*", -- recommended, use latest release instead of latest commit
		lazy = true,
		-- ft = "markdown",
		-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
		event = {
			-- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
			-- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
			"BufReadPre /home/ani/data/obsidian-vault/*.md",
			"BufNewFile /home/ani/data/obsidian-vault/*.md",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-telescope/telescope.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			workspaces = {
				{
					name = "personal",
					path = "~/data/obsidian-vault/personal",
					strict = true,
					overrides = {
						attachments = {
							img_folder = "attachments",
						},
					},
				},
				{
					name = "vamana",
					path = "/home/ani/data/obsidian-vault/work/vamana/",
					strict = true, -- Use workspace path directly, don't search for parent .obsidian
					-- Override settings specific to this workspace
					overrides = {
						notes_subdir = "notes", -- new standard notes in a specific subdir
						daily_notes = {
							folder = "daily", -- Custom daily notes folder
							date_format = "%Y-%m-%d",
							-- template = "work_daily.md", -- specific template for work
						},
						attachments = {
							img_folder = "attachments",
						},
					},
				},
			},
			ui = {
				enable = false, -- using render-markdown.nvim instead
			},
			mappings = {
                -- Defines "gd" conditionally for Obsidian buffers
				["gd"] = {
					action = function()
						if require("obsidian").util.cursor_on_markdown_link() then
							return vim.cmd("ObsidianFollowLink")
						else
							return vim.lsp.buf.definition()
						end
					end,
					opts = { buffer = true, expr = false },
				},
				-- Toggle check-boxes.
				["<leader>ch"] = {
					action = function()
						return require("obsidian").util.toggle_checkbox()
					end,
					opts = { buffer = true },
				},
				-- Smart action depending on context, either follow link or toggle checkbox.
				["<cr>"] = {
					action = function()
						return require("obsidian").util.smart_action()
					end,
					opts = { buffer = true, expr = true },
				},
			},
		},
	},
}
