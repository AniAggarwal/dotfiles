local M = {}

-- Show workspace picker and switch, then run callback or ObsidianQuickSwitch
M.select_workspace = function(callback)
	local ok, obsidian = pcall(require, "obsidian")
	if not ok then
		vim.notify("obsidian.nvim not loaded", vim.log.levels.ERROR)
		return
	end

	local client = obsidian.get_client()
	local workspaces = client.opts.workspaces

	-- If only one workspace, switch directly
	if #workspaces == 1 then
		client:switch_workspace(workspaces[1].name, { lock = true })
		if callback then
			callback()
		else
			vim.cmd("ObsidianQuickSwitch")
		end
		return
	end

	-- Multiple workspaces: show picker
	vim.ui.select(workspaces, {
		prompt = "Select Obsidian Workspace:",
		format_item = function(ws)
			local marker = (client.current_workspace and client.current_workspace.name == ws.name) and "* " or "  "
			return marker .. ws.name
		end,
	}, function(selected)
		if selected then
			client:switch_workspace(selected.name, { lock = true })
			if callback then
				callback()
			else
				vim.cmd("ObsidianQuickSwitch")
			end
		end
	end)
end

-- Run an obsidian command with workspace selection first
M.run_with_workspace = function(cmd)
	M.select_workspace(function()
		vim.cmd(cmd)
	end)
end

-- Launch function for onvim alias - directly opens workspace picker
M.launch = function()
	M.select_workspace(function()
		vim.cmd("ObsidianQuickSwitch")
	end)
end

return M
