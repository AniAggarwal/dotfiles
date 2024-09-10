return {
  -- Onedark colorscheme
  {
    "navarasu/onedark.nvim",
    lazy = false, -- Ensure it's not lazy-loaded, to apply immediately
    priority = 1000, -- High priority to load this first
    config = function()
      local palette = require("onedark.palette").dark

      -- TODO: figure out color highlighting and whatnot later
      require("onedark").setup({
        style = "dark",
        -- colors = {
        --   bg = palette.bg0,
        --   bg2 = palette.bg1,
        --   fg = palette.fg,
        --   blue = palette.blue,
        -- },
        highlights = {
          FloatBorder = { bg = palette.bg0, fg = palette.fg }, -- Keep the border but match the background to the main background
          NormalFloat = { bg = palette.bg0 }, -- Match the background of the floating window to the main background
          -- Pmenu = { fg = palette.fg, bg = palette.bg1 },
          -- PmenuSel = { fg = palette.bg1, bg = palette.blue },
          -- CmpItemMenu = { fg = palette.fg, bg = palette.bg1 },
        },
      })

      -- Load the color scheme
      require("onedark").load()
    end,
  },

  -- nvim web devicons
    {
      {
        "nvim-tree/nvim-web-devicons",
        lazy = false,  -- Ensure it loads at startup, many plugins use this
        opts = {
          color_icons = true,  
          default = true,      
          strict = true,       
        }
      }
    },

{
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    event = "BufRead",  -- Lazy load when a buffer is opened
    opts = {
      options = {
        close_command = "Bdelete! %d",
        right_mouse_command = "buffer %d",
        middle_mouse_command = "Bdelete! %d",
        offsets = {
          {
            filetype = "NvimTree",
            padding = 1,
            separator = false,
          },
        },
        diagnostics = "nvim_lsp",
      },
      highlights = {
        fill = {
          bg = "#282C34",  -- Manually filling background to match theme
        },
      },
    },
  keys = {
    -- Navigate buffers
    { "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
    
    -- Move buffers
    { "<C-M-l>", "<cmd>BufferLineMoveNext<CR>", desc = "Move buffer right" },
    { "<C-M-h>", "<cmd>BufferLineMovePrev<CR>", desc = "Move buffer left" },

    -- Close buffers
    { "<S-q>", "<cmd>Bdelete<CR>", mode = "n", desc = "Close buffer" }
  },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VimEnter",  -- Lazy load when entering Neovim
    opts = {
      options = {
        theme = "onedark",
        globalstatus = true,
        disabled_filetypes = { "alpha" },
      },
      sections = {
        lualine_x = { "encoding", "filetype", "' ' .. os.getenv('CONDA_DEFAULT_ENV')" },
      },
    },
  },
{
    "moll/vim-bbye",
    cmd = { "Bdelete", "Bwipeout" },  -- Lazy-load when these commands are used
  },

{
  "kyazdani42/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle Explorer" },
  },
  opts = {
    disable_netrw = true,
    diagnostics = {
      enable = true,
    },
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    update_focused_file = {
      enable = true,
      update_root = true,
    },
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- Use default mappings
      api.config.mappings.default_on_attach(bufnr)

      -- Remove default <C-x> keymap
      vim.keymap.set("n", "<C-x>", "", { buffer = bufnr })
      vim.keymap.del("n", "<C-x>", { buffer = bufnr })

      -- Add custom keymap for horizontal split
      vim.keymap.set("n", "<C-s>", api.node.open.horizontal, opts("Open: Horizontal Split"))
    end,
  },
  config = function(_, opts)
    require("nvim-tree").setup(opts)

    -- Auto-open nvim-tree when Vim starts in a directory
    local function open_nvim_tree(data)
      local directory = vim.fn.isdirectory(data.file) == 1
      if not directory then return end

      -- Create a new, empty buffer
      vim.cmd.enew()
      -- Wipe the directory buffer
      vim.cmd.bw(data.buf)
      -- Change to the directory
      vim.cmd.cd(data.file)
      -- Open the tree
      require("nvim-tree.api").tree.open()
    end

    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
  end,
},


{
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
  }
},


{
  "stevearc/dressing.nvim",
  opts = {
    input = {
      -- TODO: figure out if this is needed
      -- win_options = {
      --   winblend = 10,
      --   winhighlight = "NormalFloat:DiagnosticError", -- You customized this
      -- },
      mappings = {
        i = {
          ["<C-n>"] = "HistoryPrev",
          ["<C-p>"] = "HistoryNext",
        },
      },
      -- TODO: figure out if this is needed
      -- get_config = function(opts)
      --   if opts.kind == "legendary.nvim" then
      --     return {
      --       telescope = {
      --         sorter = require("telescope.sorters").fuzzy_with_index_bias({}),
      --       },
      --     }
      --   else
      --     return {}
      --   end
      -- end,
    },
    -- TODO: figure out if this is needed
    -- select = {
    --   fzf = {
    --     window = {
    --       width = 0.5, -- Custom fzf window size
    --       height = 0.4, -- Custom fzf window size
    --     },
    --   },
    --   fzf_lua = {
    --     winopts = {
    --       width = 0.5, -- Custom fzf_lua window size
    --       height = 0.4, -- Custom fzf_lua window size
    --     },
    --   },
    --   nui = {
    --     win_options = {
    --       winblend = 10, -- You customized this
    --     },
    --   },
    --   builtin = {
    --     max_width = { 140, 0.8 }, -- You customized this
    --     min_width = { 40, 0.2 }, -- You customized this
    --     max_height = 0.9, -- You customized this
    --     min_height = { 10, 0.2 }, -- You customized this
    --   },
    -- },
  },
},

{
  "stevearc/aerial.nvim",
  keys = {
    { "<leader>s", "<cmd>AerialToggle<CR>", desc = "Symbols Outline" },
  },
  opts = {
    backends = { "lsp", "treesitter", "markdown", "man" },
    layout = {
      min_width = { 20, 0.1 },
      max_width = { 120, 0.3 },
      default_direction = "prefer_right",
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
},

{
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    position = "bottom",
    open_split = { "<c-s>" },  -- Open buffer in horizontal split
    auto_preview = false,  -- Disable automatic preview, use <CR> or K to preview
    use_diagnostic_signs = false,  -- Don't use diagnostic signs
  },
  keys = {
    { "gr", "<cmd>TroubleToggle lsp_references<CR>", desc = "Trouble LSP References" },
    { "gL", "<cmd>TroubleToggle document_diagnostics<CR>", desc = "Trouble Document Diagnostics" },
  },
},

{
  "RRethy/vim-illuminate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()

require("illuminate").configure({
	filetypes_denylist = {
		"dirvish",
		"fugitive",
		"alpha",
		"NvimTree",
	},
})
end
},


{
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  opts = {
    stages = "fade",
    timeout = 500,
  },
  config = function(_, opts)
    require("notify").setup(opts)
    -- Set notify as the default notification handler for Neovim
    vim.notify = require("notify")
  end,
},



{
  "goolord/alpha-nvim",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Header section
    dashboard.section.header.val = {
      [[                               __                ]],
      [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
      [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
      [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
      [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
      [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
    }

    -- Buttons section
    dashboard.section.buttons.val = {
      dashboard.button("f", " " .. " Find file", ":Telescope find_files<CR>"),
      dashboard.button("e", " " .. " New file", ":ene <BAR> startinsert <CR>"),
      dashboard.button("p", " " .. " Find project", ":lua require('telescope').extensions.projects.projects()<CR>"),
      dashboard.button("r", "󰄉 " .. " Recent files", ":Telescope oldfiles<CR>"),
      dashboard.button("t", " " .. " Find text", ":Telescope live_grep <CR>"),
      dashboard.button("c", " " .. " Config", ":e ~/.config/nvim/init.lua <CR>"),
      dashboard.button("q", " " .. " Quit", ":qa<CR>"),
    }

    -- Footer section with dynamic content
    local function footer()
      local plugins_count = vim.fn.len(vim.fn.globpath("~/.local/share/nvim/site/pack/packer/start", "*", 0, 1))
      local v = vim.version()
      local datetime = os.date(" %d-%m-%Y   %H:%M:%S")
      local platform = " Linux"
      return string.format("󰂖 %d   v%d.%d.%d %s  %s", plugins_count, v.major, v.minor, v.patch, platform, datetime)
    end

    dashboard.section.footer.val = footer()
    dashboard.section.footer.opts.hl = "Type"
    dashboard.section.header.opts.hl = "Include"
    dashboard.section.buttons.opts.hl = "Keyword"

    dashboard.opts.opts.noautocmd = true
    alpha.setup(dashboard.opts)
  end,
},


}
