local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- Install your plugins here
-- Can pin them to specific commit. Ex: "use { "wbthomason/packer.nvim", commit = "00ec5adef58c5ff9a07f11f45903b9dbbaa1b422" }"
return packer.startup(function(use)
	-- My plugins here

	use({ "wbthomason/packer.nvim" }) -- Have packer manage itself

	-- Colorschemes and looks
	use({
		"navarasu/onedark.nvim",
	})
	use({
		"nvim-tree/nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({
				color_icons = true,
				default = true,
				strict = true,
			})
		end,
	})
	use({
		"folke/zen-mode.nvim",
		config = function()
			require("zen-mode")
		end,
	})

	use({ "akinsho/bufferline.nvim" }) -- Bufferline
	use({ "moll/vim-bbye" }) -- allow buffers to be closed properly
	use({ "nvim-lualine/lualine.nvim" }) -- status line

	use({ "goolord/alpha-nvim" }) -- startup page

	use({ "stevearc/dressing.nvim" }) -- use nice ui for all vim.input and vim.select events

	-- Symbols outline on side of code
	use({
		"simrat39/symbols-outline.nvim",
	})
	use({ "stevearc/aerial.nvim" })

	-- LSP
	use({ "williamboman/mason.nvim" })
	use({ "williamboman/mason-lspconfig.nvim" }) -- grab lsp and similar
	use({ "neovim/nvim-lspconfig" }) -- enable LSP

	use({ "nvimtools/none-ls.nvim", requires = "nvimtools/none-ls-extras.nvim" }) -- for formatters and linters
	use({ "RRethy/vim-illuminate" })
	use({ "nvim-lua/plenary.nvim" }) -- Useful lua functions used by lots of plugins

	-- Language specific
	use({ "mfussenegger/nvim-jdtls" }) -- allows full use of Java jdtls server
	use({ "p00f/clangd_extensions.nvim" }) -- extended C support in LSP
	use({
		"folke/neodev.nvim",
		config = function()
			require("neodev").setup({
				library = { plugins = { "nvim-dap-ui" }, types = true },
			})
		end,
	}) -- lsp and docs for neovim lua api

	use({ "lervag/vimtex" })

	use({
		"fei6409/log-highlight.nvim",
		config = function()
			require("log-highlight").setup({})
		end,
	}) -- log file highlighting

	-- DAP
	use({ "mfussenegger/nvim-dap" }) -- For debugger
	use({ "jay-babu/mason-nvim-dap.nvim" })
	use({ "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } })
	use({ "nvim-telescope/telescope-dap.nvim" })
	use({ "theHamsta/nvim-dap-virtual-text" })

	-- Completion
	-- use({ "hrsh7th/nvim-cmp", commit = "c3f7c54f6efed83b5657b1cf2e2a9bb7c121c6b4" }) -- use nvim-cmp as completion engine
	use({ "hrsh7th/nvim-cmp" }) -- use nvim-cmp as completion engine
	use({ "hrsh7th/cmp-buffer" }) -- completions based on current buffer contents
	use({ "hrsh7th/cmp-path" }) -- system path completions
	use({ "hrsh7th/cmp-nvim-lsp" }) -- nvim native lsp completions
	use({ "hrsh7th/cmp-nvim-lsp-document-symbol" }) -- symbols
	use({ "hrsh7th/cmp-nvim-lua" }) -- nvim lua api completions
	use({ "hrsh7th/cmp-nvim-lsp-signature-help" }) -- method signature while typing
	use({ "saadparwaiz1/cmp_luasnip" }) -- snippets completions
	use({ "onsails/lspkind.nvim" }) -- auto icons in cmp

	-- Github Copilot
	-- Intergrate Github Copilot with nvim-cmp
	use({
		"zbirenbaum/copilot.lua",
		config = function()
			require("copilot").setup()
		end,
	})
	use({
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup({
				method = "getCompletionsCycling",
				filetypes = {
					VimspectorPrompt = false,
				},
			})
		end,
	})

	-- GPT
	-- use({
	-- 	"jackMort/ChatGPT.nvim",
	-- 	config = function()
	-- 		require("chatgpt").setup({
	-- 			-- api_key_cmd = "cat ~/.openai-api-key",
	-- 		})
	-- 	end,
	-- 	requires = {
	-- 		"MunifTanjim/nui.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-telescope/telescope.nvim",
	-- 	},
	-- })

	-- Snippet
	use({ "L3MON4D3/LuaSnip" }) -- Snippet engine for cmp_luasnip
	use({ "rafamadriz/friendly-snippets" }) -- Extra snippets

	-- surround text with stuff
	use({
		"kylechui/nvim-surround",
		config = function()
			require("nvim-surround").setup()
		end,
	})
	use({
		"ggandor/leap.nvim",
		config = function()
			require("leap").set_default_keymaps()
		end,
	}) -- quick movement

	use({ "tpope/vim-repeat" }) -- allow repeating commands
	use({ "windwp/nvim-autopairs" }) -- Autopairs, integrates with both cmp and treesitter
	use({ "numToStr/Comment.nvim" }) -- comment out easily
	use({ "folke/todo-comments.nvim" }) -- Display and find todo and similar comments
	use({ "AndrewRadev/linediff.vim" }) -- diff on line selections

	-- Telescope
	use({ "nvim-telescope/telescope.nvim" })
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" }) -- for faster searching

	-- Trouble
	use({ "folke/trouble.nvim" }) -- Shows issues in panel

	-- Treesitter
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
	use({
		"nvim-treesitter/nvim-treesitter-textobjects",
		after = "nvim-treesitter",
		requires = "nvim-treesitter/nvim-treesitter",
	})

	-- Git
	use({ "lewis6991/gitsigns.nvim" }) -- show sings of git changes
	use({ "kdheepak/lazygit.nvim" }) -- lazygit popup window
	-- Git diff viewer
	use({
		"sindrets/diffview.nvim",
		requires = "nvim-lua/plenary.nvim",
	})

	-- Quality of life
	use({ "kyazdani42/nvim-tree.lua" }) -- Explorer/tree on left side
	use({ "ahmedkhalf/project.nvim" }) -- easily move between projects
	use({ "folke/which-key.nvim" }) -- show key maps
	use({ "mrjones2014/legendary.nvim" }) -- search key maps
	use({
		"danymat/neogen",
		config = function()
			require("neogen").setup({
				snippet_engine = "luasnip",
				languages = { python = { templates = { "google_docstrings" } } },
			})
		end,
		requires = "nvim-treesitter/nvim-treesitter",
	}) -- documentation generation

	use({
		"chipsenkbeil/distant.nvim",
		branch = "v0.3",
		config = function()
			require("distant"):setup()
		end,
	})

	-- image viewing
	-- use({
	-- 	"edluffy/hologram.nvim",
	-- 	config = function()
	-- 		require("hologram").setup({
	-- 			-- WIP automatic markdown image display, may be prone to breaking
	-- 			auto_display = true,
	-- 		})
	-- 	end,
	-- })

	-- faster startuptime
	use({
		"lewis6991/impatient.nvim",
		config = function()
			require("impatient").enable_profile()
		end,
	})
	use({ "dstein64/vim-startuptime" }) -- show how long plugins take to load

	-- Automatically sync to remote server
	use({ "kenn7/vim-arsync", requires = {
		{ "prabirshrestha/async.vim" },
	} })

	-- Markdown preview
	use({
		"iamcco/markdown-preview.nvim",
		run = "cd app && npm install",
		setup = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	})

	use({ "chrisbra/csv.vim" })

	-- Jupyter Notebook
	use({
		"kiyoon/jupynium.nvim",
		build = "micromamba run -n jupyter pip install .",
		-- enabled = vim.fn.isdirectory(vim.fn.expand "~/miniconda3/envs/jupynium"),
	})

	-- Movement and Productivity
	use({ "mrjones2014/smart-splits.nvim", run = "./kitty/install-kittens.bash" })

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
