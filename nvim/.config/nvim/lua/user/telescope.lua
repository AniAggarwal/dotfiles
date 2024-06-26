local telescope = require("telescope")
local actions = require("telescope.actions")

telescope.setup({
	defaults = {
		prompt_prefix = " ",
		selection_caret = " ",
		path_display = { "smart" }, -- only display important part of file path
		file_ignore_patterns = { ".git/", "doc/" }, -- ignore file paths matching these regex
		mappings = {
			i = {
				["<C-s>"] = actions.select_horizontal,
			},
			n = {
				["<C-s>"] = actions.select_horizontal,
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
			fuzzy = true, -- false will only do exact matching
			override_generic_sorter = true, -- override the generic sorter
			override_file_sorter = true, -- override the file sorter
			case_mode = "smart_case", -- or "ignore_case" or "respect_case"
			-- the default case_mode is "smart_case"
		},
	},
})

require("telescope").load_extension("fzf")
require("telescope").load_extension("projects")
require("telescope").load_extension("lazygit")
require("telescope").load_extension("dap")
