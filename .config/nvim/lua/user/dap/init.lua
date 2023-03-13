-- Must be required in this order
require("mason").setup()
require("mason-nvim-dap").setup({
	ensure_installed = { "codelldb" },
	automatic_setup = true,
})
local dap = require("dap")
local dapui = require("dapui")
dapui.setup()

require("mason-nvim-dap").setup_handlers({
	function(source_name)
		require("mason-nvim-dap.automatic_setup")(source_name)
	end,
	codelldb = function(source_name)
		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = "/home/ani/.local/share/nvim/mason/packages/codelldb/codelldb",
				args = { "--port", "${port}" },
			},
		}

		dap.configurations.c = {
			{
				name = "Launch file",
				type = "codelldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
	end,
})

require("nvim-dap-virtual-text").setup({})

-- Auto open dapui when dap starts
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end
