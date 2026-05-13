return {

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ensure_installed = {
				"python",
				"c",
				"lua",
				"bash",
				"markdown",
				"markdown_inline",
			}
			local ts_config = require("nvim-treesitter.config")
			local installed = ts_config.get_installed("parsers")
			local to_install = vim.tbl_filter(function(lang)
				return not vim.tbl_contains(installed, lang)
			end, ensure_installed)
			if #to_install > 0 then
				require("nvim-treesitter").install(to_install)
			end

			vim.api.nvim_create_autocmd("FileType", {
				desc = "Start treesitter highlighting and indent (auto-install parser if needed)",
				callback = function(ev)
					local bufnr = ev.buf
					local ft = vim.bo[bufnr].filetype
					-- vimtex owns tex/latex highlighting
					if ft == "tex" or ft == "latex" then
						return
					end

					local lang = vim.treesitter.language.get_lang(ft) or ft
					if not vim.tbl_contains(ts_config.get_installed("parsers"), lang) then
						if vim.tbl_contains(ts_config.get_available(), lang) then
							require("nvim-treesitter").install({ lang })
						end
						return
					end

					if not pcall(vim.treesitter.start, bufnr, lang) then
						return
					end
					-- ts python indent is poor; keep filetype indent
					if ft ~= "python" then
						vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		event = "BufReadPost",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = { lookahead = true },
				move = { set_jumps = true },
			})

			local select = require("nvim-treesitter-textobjects.select")
			local move = require("nvim-treesitter-textobjects.move")
			local swap = require("nvim-treesitter-textobjects.swap")

			local function map_select(lhs, query, desc)
				vim.keymap.set({ "x", "o" }, lhs, function()
					select.select_textobject(query, "textobjects")
				end, { desc = desc })
			end

			local function map_move(lhs, dir, query, desc)
				vim.keymap.set({ "n", "x", "o" }, lhs, function()
					move[dir](query, "textobjects")
				end, { desc = desc })
			end

			map_select("af", "@function.outer", "outer function")
			map_select("if", "@function.inner", "inner function")
			map_select("ac", "@class.outer", "outer class")
			map_select("ic", "@class.inner", "inner class")
			map_select("aa", "@parameter.outer", "outer argument")
			map_select("ia", "@parameter.inner", "inner argument")

			map_move("]m", "goto_next_start", "@function.outer", "Next function start")
			map_move("]]", "goto_next_start", "@class.outer", "Next class start")
			map_move("]M", "goto_next_end", "@function.outer", "Next function end")
			map_move("][", "goto_next_end", "@class.outer", "Next class end")
			map_move("[m", "goto_previous_start", "@function.outer", "Prev function start")
			map_move("[[", "goto_previous_start", "@class.outer", "Prev class start")
			map_move("[M", "goto_previous_end", "@function.outer", "Prev function end")
			map_move("[]", "goto_previous_end", "@class.outer", "Prev class end")

			vim.keymap.set("n", "<leader>xp", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "Swap with next parameter" })
			vim.keymap.set("n", "<leader>xP", function()
				swap.swap_previous("@parameter.inner")
			end, { desc = "Swap with prev parameter" })
		end,
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
			-- ty: installed but not auto-started; run :LspStart ty to test manually
			-- jdtls: we handle it ourselves (see below)
			automatic_enable = { exclude = { "jdtls", "ty" } },
		},
		config = function(_, opts)
			require("mason").setup()

			-- Default LSP config (applies to all mason-enabled servers)
			local capabilities =
				require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
			capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

			vim.lsp.config("*", { capabilities = capabilities })

			-- basedpyright (type checking + LSP features: hover, go-to-def, completions, references)
			-- Linting/formatting handled by ruff
			vim.lsp.config("basedpyright", {
				capabilities = capabilities,
				settings = {
					basedpyright = {
						disableOrganizeImports = true,
						analysis = {
							typeCheckingMode = "strict",
						},
					},
				},
			})

			-- ty: not mature enough yet, revisit later
			-- vim.lsp.config("ty", {
			-- 	capabilities = capabilities,
			-- 	settings = {
			-- 		ty = {},
			-- 	},
			-- })

			-- ruff (linting + formatting, replaces black/isort/flake8)
			vim.lsp.config("ruff", {
				capabilities = capabilities,
				init_options = {
					settings = {
						lineLength = 120,
						lint = {
							select = {
								"E", -- pycodestyle errors
								"W", -- pycodestyle warnings
								"F", -- pyflakes
								"I", -- isort
								"B", -- flake8-bugbear
								"C4", -- flake8-comprehensions
								"UP", -- pyupgrade
								"SIM", -- flake8-simplify
								"TCH", -- type-checking imports
								"PTH", -- pathlib
								"N", -- pep8-naming
								"RUF", -- ruff-specific
							},
							ignore = {
								"E501", -- line length (formatter handles this)
								-- Personal preferences (not in org standard):
								-- "E402", -- module-level import not at top of file
								-- "E203", -- whitespace before ':'
								-- "E731", -- do not assign a lambda expression
							},
						},
					},
				},
			})

			-- Disable hover/definition for ruff, let basedpyright handle it
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_attach_disable_duplicate_providers", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "ruff" then
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
