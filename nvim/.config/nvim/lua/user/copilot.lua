-- Sets up copilot and copilot_cmp for completions
require("copilot").setup({})
require("copilot_cmp").setup({
	method = "getCompletionsCycling",
})

-- use({ "https://github.com/github/copilot.vim" }) -- Only needed to config copilot.lua first time
