local status_ok, trouble = pcall(require, "trouble")
if not status_ok then
	return
end

require("trouble").setup({
	position = "bottom",
    open_split = { "<c-s>" }, -- open buffer in horizontal split
    auto_preview = false, -- use K or <CR> to hover/jump rather than previewing
    use_diagnostic_signs = false
})
