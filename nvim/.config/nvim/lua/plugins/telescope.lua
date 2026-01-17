-- Custom Telescope picker for Obsidian commands
local function obsidian_picker()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local launcher = require("obsidian_launcher")

  -- Commands marked with workspace = true will prompt for workspace selection first
  local obsidian_commands = {
    { name = "Quick Switch", cmd = "ObsidianQuickSwitch", desc = "Jump to another note", workspace = true },
    { name = "Search", cmd = "ObsidianSearch", desc = "Search text in vault", workspace = true },
    { name = "New Note", cmd = "ObsidianNew", desc = "Create a new note", workspace = true },
    { name = "Today", cmd = "ObsidianToday", desc = "Open today's daily note", workspace = true },
    { name = "Yesterday", cmd = "ObsidianYesterday", desc = "Open yesterday's daily note", workspace = true },
    { name = "Tomorrow", cmd = "ObsidianTomorrow", desc = "Open tomorrow's daily note", workspace = true },
    { name = "Daily Notes", cmd = "ObsidianDailies", desc = "List daily notes", workspace = true },
    { name = "Templates", cmd = "ObsidianTemplate", desc = "Insert a template", workspace = true },
    { name = "New from Template", cmd = "ObsidianNewFromTemplate", desc = "Create note from template", workspace = true },
    { name = "Tags", cmd = "ObsidianTags", desc = "List all tags", workspace = true },
    { name = "Backlinks", cmd = "ObsidianBacklinks", desc = "Show backlinks to current note" },
    { name = "Links", cmd = "ObsidianLinks", desc = "Show links in current note" },
    { name = "TOC", cmd = "ObsidianTOC", desc = "Table of contents for current note" },
    { name = "Open in App", cmd = "ObsidianOpen", desc = "Open in Obsidian app" },
    { name = "Paste Image", cmd = "ObsidianPasteImg", desc = "Paste image from clipboard" },
    { name = "Rename", cmd = "ObsidianRename", desc = "Rename current note" },
    { name = "Workspaces", cmd = "ObsidianWorkspace", desc = "Switch workspace" },
  }

  pickers.new({}, {
    prompt_title = "Obsidian",
    finder = finders.new_table({
      results = obsidian_commands,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name .. " - " .. entry.desc,
          ordinal = entry.name .. " " .. entry.desc,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection.value.workspace then
          -- Workspace-sensitive command: prompt for workspace first
          launcher.run_with_workspace(selection.value.cmd)
        else
          vim.cmd(selection.value.cmd)
        end
      end)
      return true
    end,
  }):find()
end

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
    { "<leader>fo", obsidian_picker, desc = "Obsidian commands"},
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

