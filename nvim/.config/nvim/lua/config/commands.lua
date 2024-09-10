function SpellSuggest()
	local word = vim.fn.expand("<cword>")
	local suggestions = vim.fn.spellsuggest(word)
	vim.ui.select(
		suggestions,
		{},
		vim.schedule_wrap(function(selected)
			if selected then
				vim.api.nvim_feedkeys("ciw" .. selected, "n", true)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)
			end
		end)
	)
end

vim.api.nvim_create_user_command("SpellSuggest", SpellSuggest, {})

function DisableCopilot()
	local target_name = "copilot"
	local clients = vim.lsp.get_clients()

	for _, client in ipairs(clients) do
		if client.name == target_name then
			vim.lsp.stop_client(client.id)
			print("Copilot client detached.")
			return
		end
	end

	print("Copilot client not found.")
end

vim.api.nvim_create_user_command("DisableCopilot", DisableCopilot, {})
