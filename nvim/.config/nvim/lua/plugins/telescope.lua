return {

{
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",  -- Lazy-load on :Telescope command
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  keys = {
    -- Telescope Keymaps
    { "<leader>fr", "<cmd>Telescope resume<CR>", desc = "Resume"},
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files"},
    { "<leader>ft", "<cmd>Telescope live_grep<CR>", desc = "Find text in project"},
    { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "Projects"},
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers"},
    { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands"},
    { "<leader>fl", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Current buffer"},
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics"},
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols"},
    { "<leader>fT", "<cmd>Trouble<CR>", desc = "Trouble"},
    { "<leader>fL", "<cmd>Legendary<CR>", desc = "Search with Legendary"},
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup({
    defaults = {
      prompt_prefix = " ",
      selection_caret = " ",
      path_display = { "smart" },
      file_ignore_patterns = { ".git/", "doc/" },
      mappings = {
        i = {
          ["<C-s>"] = require("telescope.actions").select_horizontal,
        },
        n = {
          ["<C-s>"] = require("telescope.actions").select_horizontal,
        },
      },
      hidden = true,
      layout_strategy = "horizontal",
      layout_config = {
        horizontal = {
          preview_width = 0.5,
        },
        width = 0.85,
      },
    },
    pickers = {
      find_files = {
        find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
    })
    telescope.setup(opts)
    -- TODO: enable these once they are added
    -- telescope.load_extension("fzf")
    -- telescope.load_extension("projects")
    -- telescope.load_extension("lazygit")
    -- telescope.load_extension("dap")
    telescope.load_extension("notify")
  end,
}


}

