require("legendary").setup({
	select_prompt = "legendary.nvim",

	-- auto-register commands added via which_key
	extensions = {
		nvim_tree = true,
		diffview = true,
		which_key = { auto_register = true },
	},
})
