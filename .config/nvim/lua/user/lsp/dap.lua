local dap_status_ok, dap = pcall(require, "dap")
if not dap_status_ok then
	return
end

dap.adapters.python = {
	type = "executable",
	command = vim.fn.stdpath("cache") .. "data" .. "mason/packages/debugpy/venv/bin/python" ,
	args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		-- program = "${file}",
	},
}
