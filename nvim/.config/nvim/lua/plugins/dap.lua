return {
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		config = function()
			local dap = require("dap")
			-- Python - NOTE: this isn't needed anymore with nvim-dap-python plugin
			-- dap.adapters.python = function(cb, config)
			-- 	if config.request == "attach" then
			-- 		---@diagnostic disable-next-line: undefined-field
			-- 		local port = (config.connect or config).port
			-- 		---@diagnostic disable-next-line: undefined-field
			-- 		local host = (config.connect or config).host or "127.0.0.1"
			-- 		cb({
			-- 			type = "server",
			-- 			port = assert(port, "`connect.port` is required for a python `attach` configuration"),
			-- 			host = host,
			-- 			options = {
			-- 				source_filetype = "python",
			-- 			},
			-- 		})
			-- 	else
			-- 		cb({
			-- 			type = "executable",
			-- 			command = "/home/ani/micromamba/envs/utils/bin/python",
			-- 			args = { "-m", "debugpy.adapter" },
			-- 			options = {
			-- 				source_filetype = "python",
			-- 			},
			-- 		})
			-- 	end
			-- end
			--
			-- dap.configurations.python = {
			-- 	{
			-- 		-- The first three options are required by nvim-dap
			-- 		type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
			-- 		request = "launch",
			-- 		name = "Launch file",
			--
			-- 		-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
			--
			-- 		program = "${file}", -- This configuration will launch the current file if used.
			-- 		pythonPath = function()
			-- 			-- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
			-- 			-- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
			-- 			-- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
			-- 			local cwd = vim.fn.getcwd()
			-- 			if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
			-- 				return cwd .. "/venv/bin/python"
			-- 			elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
			-- 				return cwd .. "/.venv/bin/python"
			-- 			-- check if env var CONDA_PREFIX is set and if so use it
			-- 			elseif os.getenv("CONDA_PREFIX") then
			-- 				return os.getenv("CONDA_PREFIX") .. "/bin/python"
			-- 			else
			-- 				return "/usr/bin/python"
			-- 			end
			-- 		end,
			-- 	},
			-- }

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
			require("dap-python").setup("/home/ani/micromamba/envs/utils/bin/python")
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
