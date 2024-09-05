return {

{
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",  -- Automatically update parsers on install/update
  event = { "BufReadPost", "BufNewFile" },  -- Lazy load treesitter when opening a file
  opts = {
    ensure_installed = { "python", "c", "lua", "bash" },  -- List of languages to install
    auto_install = true,
    ignore_install = { "latex" },  -- Parsers to ignore
    highlight = {
      enable = true,
      disable = { "latex" },  -- Languages for which highlighting is disabled
    },
    autopairs = {
      enable = true,  -- Enable autopairs integration
    },
    indent = {
      enable = true,
      disable = { "python", "latex" },  -- Disable indent for these languages
    },
  },
},

{
  "nvim-treesitter/nvim-treesitter-textobjects",
  event = "BufReadPost",  -- Lazy load after opening a buffer
  dependencies = { "nvim-treesitter/nvim-treesitter" },  -- Ensure nvim-treesitter is loaded first
},

}

