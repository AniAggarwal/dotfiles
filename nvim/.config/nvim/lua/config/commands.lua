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

vim.api.nvim_create_user_command("DiffMain", "DiffviewOpen origin/main...HEAD", {
	desc = "Diff current branch against origin/main",
})

vim.api.nvim_create_user_command("DiffUncommitted", "DiffviewOpen HEAD", {
	desc = "Diff uncommitted changes against HEAD",
})

vim.api.nvim_create_user_command("ObsidianSync", function()
	require("obsidian_sync").sync()
end, { desc = "Save enrolled vault notes, pull and push main" })
