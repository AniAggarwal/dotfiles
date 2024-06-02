-- Must be required in this order
require("mason").setup()

local dap = require("dap")
local dapui = require("dapui")
dapui.setup()

-- Python
dap.adapters.python = function(cb, config)
	if config.request == "attach" then
		---@diagnostic disable-next-line: undefined-field
		local port = (config.connect or config).port
		---@diagnostic disable-next-line: undefined-field
		local host = (config.connect or config).host or "127.0.0.1"
		cb({
			type = "server",
			port = assert(port, "`connect.port` is required for a python `attach` configuration"),
			host = host,
			options = {
				source_filetype = "python",
			},
		})
	else
		cb({
			type = "executable",
			command = "/home/ani/micromamba/envs/utils/bin/python",
			args = { "-m", "debugpy.adapter" },
			options = {
				source_filetype = "python",
			},
		})
	end
end

dap.configurations.python = {
	{
		-- The first three options are required by nvim-dap
		type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
		request = "launch",
		name = "Launch file",

		-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

		program = "${file}", -- This configuration will launch the current file if used.
		pythonPath = function()
			-- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
			-- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
			-- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
			local cwd = vim.fn.getcwd()
			if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
				return cwd .. "/venv/bin/python"
			elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
				return cwd .. "/.venv/bin/python"
			-- check if env var CONDA_PREFIX is set and if so use it
			elseif os.getenv("CONDA_PREFIX") then
				return os.getenv("CONDA_PREFIX") .. "/bin/python"
			else
				return "/usr/bin/python"
			end
		end,
	},
}

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

-- OLD
-- require("mason-nvim-dap").setup({
-- 	ensure_installed = {
-- 		-- "cppdbg",
-- 	},
-- 	automatic_setup = true,
--
-- 	handlers = {
-- 		function(source_name)
-- 			require("mason-nvim-dap").default_setup(config)
-- 		end,
-- 			cppdbg = function(source_name)
-- 				dap.adapters.cppdbg = {
-- 					id = "cppdbg",
-- 					type = "executable",
-- 					command = "/home/ani/.local/share/nvim/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
-- 				}
--
-- 				dap.configurations.c = {
-- 					{
-- 						name = "Launch file",
-- 						type = "cppdbg",
-- 						request = "launch",
-- 						program = function()
-- 							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
-- 						end,
-- 						cwd = "${workspaceFolder}",
-- 						stopOnEntry = false,
-- 					},
-- 				}
-- 				setupCommands = {
-- 					{
-- 						text = "-enable-pretty-printing",
-- 						description = "enable pretty printing",
-- 						ignoreFailures = false,
-- 					},
-- 				}
-- 			end,
-- 		},
-- })

require("nvim-dap-virtual-text").setup({})

-- Auto open dapui when dap starts
-- dap.listeners.before.attach.dapui_config = function()
-- 	dapui.open()
-- end
-- dap.listeners.before.launch.dapui_config = function()
-- 	dapui.open()
-- end
-- dap.listeners.before.event_terminated.dapui_config = function()
-- 	dapui.close()
-- end
-- dap.listeners.before.event_exited.dapui_config = function()
-- 	dapui.close()
-- end
