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

	-- -- Colorschemes and looks
	use({ "lunarvim/darkplus.nvim" })
	use({ "folke/tokyonight.nvim" })
	use({ "joshdick/onedark.vim" }) -- A lua alternative to look into monsonjeremy/onedark.nvim
	use({ "kyazdani42/nvim-web-devicons" })

	-- LSP
	use({ "neovim/nvim-lspconfig" }) -- enable LSP
	use({ "williamboman/nvim-lsp-installer" }) -- simple to use language server installer
	use({ "jose-elias-alvarez/null-ls.nvim" }) -- for formatters and linters
	use({ "RRethy/vim-illuminate" })
	use({ "nvim-lua/plenary.nvim" }) -- Useful lua functions used by lots of plugins

	-- Completion
	use({ "hrsh7th/nvim-cmp" }) -- use nvim-cmp as completion engine
	use({ "hrsh7th/cmp-buffer" })
	use({ "hrsh7th/cmp-path" })
	use({ "saadparwaiz1/cmp_luasnip" })
	use({ "hrsh7th/cmp-nvim-lsp" })
	use({ "hrsh7th/cmp-nvim-lua" })

	-- TODO: set up copilot with nvim-cmp: https://github.com/zbirenbaum/copilot-cmp
	-- TODO: which-key

	-- Snippet
	use({ "L3MON4D3/LuaSnip" }) -- Snippet engine for cmp_luasnip
	use({ "rafamadriz/friendly-snippets" }) -- Extra snippets

	-- Telescope
	use({ "nvim-telescope/telescope.nvim" })
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" }) -- for faster searching

	-- Trouble
	use({ "folke/trouble.nvim" }) -- Shows issues in panel

	-- Movement and Productivity
	use({ "https://github.com/knubie/vim-kitty-navigator", run = "cp ./*.py ~/.config/kitty/" }) -- for movement between kitty windows
	use({ "kylechui/nvim-surround" })

	-- Treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			require("nvim-treesitter.install").update({ with_sync = true })
		end,
	})

	-- Git
	use({ "lewis6991/gitsigns.nvim" })

	use({ "windwp/nvim-autopairs" }) -- Autopairs, integrates with both cmp and treesitter
	use({ "numToStr/Comment.nvim" }) -- comment out easily

	-- For later:
	-- https://github.com/phaazon/hop.nvim
	-- https://dev.to/kquirapas/neovim-on-steroids-vim-sneak-easymotion-hopnvim-4k17
	-- https://github.com/lewis6991/spellsitter.nvim

	-- use { "JoosepAlviste/nvim-ts-context-commentstring", commit = "88343753dbe81c227a1c1fd2c8d764afb8d36269" }
	-- use { "kyazdani42/nvim-tree.lua", commit = "bdb6d4a25410da35bbf7ce0dbdaa8d60432bc243" }
	-- use { "akinsho/bufferline.nvim", commit = "c78b3ecf9539a719828bca82fc7ddb9b3ba0c353" }
	-- use { "moll/vim-bbye", commit = "25ef93ac5a87526111f43e5110675032dbcacf56" }
	-- use { "nvim-lualine/lualine.nvim", commit = "3362b28f917acc37538b1047f187ff1b5645ecdd" }
	-- use { "akinsho/toggleterm.nvim", commit = "aaeed9e02167c5e8f00f25156895a6fd95403af8" }
	-- use { "ahmedkhalf/project.nvim", commit = "541115e762764bc44d7d3bf501b6e367842d3d4f" }
	-- use { "lewis6991/impatient.nvim", commit = "969f2c5c90457612c09cf2a13fee1adaa986d350" }
	-- use { "lukas-reineke/indent-blankline.nvim", commit = "6177a59552e35dfb69e1493fd68194e673dc3ee2" }
	-- use { "goolord/alpha-nvim", commit = "ef27a59e5b4d7b1c2fe1950da3fe5b1c5f3b4c94" }

	-- -- Git
	-- use { "lewis6991/gitsigns.nvim", commit = "c18e016864c92ecf9775abea1baaa161c28082c3" }

	-- -- DAP
	-- use { "mfussenegger/nvim-dap", commit = "014ebd53612cfd42ac8c131e6cec7c194572f21d" }
	-- use { "rcarriga/nvim-dap-ui", commit = "d76d6594374fb54abf2d94d6a320f3fd6e9bb2f7" }
	-- use { "ravenxrz/DAPInstall.nvim", commit = "8798b4c36d33723e7bba6ed6e2c202f84bb300de" }

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
