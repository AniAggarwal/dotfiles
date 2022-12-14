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
	use({ "lunarvim/darkplus.nvim" })
	use({ "folke/tokyonight.nvim" })
	use({ "joshdick/onedark.vim" }) -- A lua alternative to look into monsonjeremy/onedark.nvim
	use({ "kyazdani42/nvim-web-devicons" })

	use({ "akinsho/bufferline.nvim" }) -- Bufferline
	use({ "moll/vim-bbye" }) -- allow buffers to be closed properly
	use({ "nvim-lualine/lualine.nvim" }) -- status line

	use({ "goolord/alpha-nvim" }) -- startup page

	use({ "stevearc/dressing.nvim" }) -- use nice ui for all vim.input and vim.select events

	-- Symbols outline on side of code
	use({
		"simrat39/symbols-outline.nvim",
	})

	-- LSP
	use({ "neovim/nvim-lspconfig" }) -- enable LSP
	use({ "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" }) -- grab lsp and similar
	use({ "mfussenegger/nvim-dap" }) -- For debugger
	use({ "jose-elias-alvarez/null-ls.nvim" }) -- for formatters and linters
	use({ "RRethy/vim-illuminate" })
	use({ "nvim-lua/plenary.nvim" }) -- Useful lua functions used by lots of plugins

	use({ "mfussenegger/nvim-jdtls" }) -- allows full use of Java jdtls server

	-- TODO: look into dapui later
	-- use { "rcarriga/nvim-dap-ui", commit = "d76d6594374fb54abf2d94d6a320f3fd6e9bb2f7" }

	-- Completion
	use({ "hrsh7th/nvim-cmp" }) -- use nvim-cmp as completion engine
	use({ "hrsh7th/cmp-buffer" }) -- completions based on current buffer contents
	use({ "hrsh7th/cmp-path" }) -- system path completions
	use({ "saadparwaiz1/cmp_luasnip" }) -- snippets completions
	use({ "hrsh7th/cmp-nvim-lsp" }) -- nvim native lsp completions
	use({ "hrsh7th/cmp-nvim-lua" }) -- nvim lua api completions
	use({ "hrsh7th/cmp-nvim-lsp-signature-help" }) -- method signature while typing
	use({ "onsails/lspkind.nvim" }) -- auto icons in cmp

	-- Github Copilot
	-- use({ "https://github.com/github/copilot.vim" }) -- Only needed to config copilot.lua first time
	-- Intergrate Github Copilot with nvim-cmp
	-- This starts copilot server
	use({
		"zbirenbaum/copilot.lua",
		event = { "VimEnter" },
		config = function()
			vim.defer_fn(function()
				require("copilot").setup({
					panel = {
						enabled = true,
					},
				})
			end, 100)
		end,
	})
	use({
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup({
				method = "getCompletionsCycling",
			})
		end,
	})

	-- Snippet
	use({ "L3MON4D3/LuaSnip" }) -- Snippet engine for cmp_luasnip
	use({ "rafamadriz/friendly-snippets" }) -- Extra snippets

	-- Movement and Productivity
	use({ "https://github.com/knubie/vim-kitty-navigator", run = "cp ./*.py ~/.config/kitty/" }) -- for movement between kitty windows
	use({ "kylechui/nvim-surround" }) -- surround text with stuff
	use({ "ggandor/leap.nvim" }) -- quick movement
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
	-- Use commit = "addc129a4f272aba0834bd0a7b6bd4ad5d8c801b" if treesitter
    -- causes conflicts with other plugins
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })

	-- Git
	use({ "lewis6991/gitsigns.nvim" }) -- show sings of git changes
	use({ "kdheepak/lazygit.nvim" }) -- lazygit popup window

	-- Quality of life
	use({ "kyazdani42/nvim-tree.lua" }) -- Explorer/tree on left side
	use({ "ahmedkhalf/project.nvim" }) -- easily move between projects
	use({ "folke/which-key.nvim" }) -- show key maps
	use({ "mrjones2014/legendary.nvim" }) -- search key maps

	use({ "lewis6991/impatient.nvim" }) -- faster startuptime
	use({ "dstein64/vim-startuptime" }) -- show how long plugins take to load

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
