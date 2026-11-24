return {
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		config = function()
			local dap = require("dap")
			-- C/C++
			dap.adapters.gdb = {
				type = "executable",
				command = "gdb",
				args = { "-i", "dap" },
			}
			dap.configurations.c = {
				{
					name = "Launch",
					type = "gdb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtBeginningOfMainSubprogram = false,
				},
			}
		end,
		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<F6>",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<F7>",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<F8>",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
		},
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		opts = {},
		keys = {
			{ "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", desc = "Toggle breakpoint" },
			{
				"<leader>dB",
				-- "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
				function()
					require("dap").set_breakpoint(nil, nil, vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Set breakpoint",
			},
			{
				"<leader>de",
				-- "<cmd>lua require'dap'.set_exception_breakpoints({'all'})<CR>",
				function()
					require("dap").set_exception_breakpoints({ "all" })
				end,
				desc = "Exception breakpoints",
			},
			{
				"<leader>dl",
				-- "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>",
				function()
					require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
				end,
				desc = "Log point",
			},
			-- { "<leader>dS", "<cmd>lua require'dap'.close()<CR>", desc = "Stop" },
			-- { "<leader>dk", "<cmd>lua require'dap.ui.widgets'.hover()<CR>", desc = "Hover info" },
			-- { "<leader>du", "<cmd>lua require'dapui'.toggle()<CR>", desc = "Toggle DAP UI" },
			{
				"<leader>ds",
				function()
					require("dap").continue()
				end,
				desc = "Start/Continue",
			},
			{
				"<leader>dS",
				function()
					require("dap").close()
				end,
				desc = "Stop",
			},
			{
				"<leader>dk",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Hover info",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle DAP UI",
			},

			-- TODO: eventually write a function that runs the appropriate language config as needed
			-- nnoremap <silent> <leader>dn :lua require('dap-python').test_method()<CR>
			-- nnoremap <silent> <leader>df :lua require('dap-python').test_class()<CR>
			-- vnoremap <silent> <leader>ds <ESC>:lua require('dap-python').debug_selection()<CR>
			-- { "<leader>dc", require("jdtls").test_class, desc = "Unit test class" },
			-- { "<leader>dm", require("jdtls").test_nearest_method, desc = "Unit test nearest method" },
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "Open REPL",
			},
		},
	},
	{
		"mfussenegger/nvim-dap-python",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			-- debugpy lives in the uv venv made by ~/bin/nvim-python-setup; the debuggee's
			-- interpreter comes from VIRTUAL_ENV or the project's .venv (dap-python default)
			require("dap-python").setup(vim.fn.stdpath("data") .. "/python/bin/python")
			table.insert(require("dap").configurations.python, {
				-- more options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
				type = "python",
				request = "launch",
				name = "file:args|all code",
				program = "${file}",
				args = function()
					local args_string = vim.fn.input("Arguments: ")
					local utils = require("dap.utils")
					if utils.splitstr and vim.fn.has("nvim-0.10") == 1 then
						return utils.splitstr(args_string)
					end
					return vim.split(args_string, " +")
				end,
				justMyCode = false,
			})
		end,
	},
}
