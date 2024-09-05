return {
{
  "danymat/neogen",
  cmd = "Neogen",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "<leader>C", "<cmd>Neogen<CR>", desc = "Generate Documentation" },
  },
  opts = {
    snippet_engine = "luasnip",
    languages = {
      python = { templates = { "google_docstrings" } },
    },
  }
},
}
