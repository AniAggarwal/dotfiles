local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
	return
end

bufferline.setup({

	options = {
		close_command = "Bdelete! %d",
		right_mouse_command = "buffer %d",
		middle_mouse_command = "Bdelete! %d",
		offsets = {
			{
				filetype = "NvimTree",
				padding = 1,
				separator = false,
			},
		},
		diagnostics = "nvim_lsp",
	},
	highlights = {
		fill = {
            -- Manually filling background to have same fill as theme
            bg = "#282C34"
		},
	},
})
