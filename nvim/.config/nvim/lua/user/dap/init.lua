-- Must be required in this order
require("mason").setup()

local dap = require("dap")
local dapui = require("dapui")
dapui.setup()

require("mason-nvim-dap").setup({
	ensure_installed = { "cppdbg" },
	automatic_setup = true,

	handlers = {
		function(source_name)
			require("mason-nvim-dap.automatic_setup")(source_name)
		end,
		cppdbg = function(source_name)
			dap.adapters.cppdbg = {
				id = "cppdbg",
				type = "executable",
				command = "/home/ani/.local/share/nvim/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
			}

			dap.configurations.c = {
				{
					name = "Launch file",
					type = "cppdbg",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			setupCommands = {
				{
					text = "-enable-pretty-printing",
					description = "enable pretty printing",
					ignoreFailures = false,
				},
			}
		end,
	},
})

require("nvim-dap-virtual-text").setup({})

-- Auto open dapui when dap starts
dap.listeners.before.attach.dapui_config = function()
	dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
	dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
	dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
	dapui.close()
end
