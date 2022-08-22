local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	return
end

lualine.setup({
	options = {
		theme = "onedark",
		globalstatus = true,
        disabled_filetypes = {
            "alpha"
        }
	},
	sections = {
		lualine_x = { "encoding", "filetype", "' ' .. os.getenv('CONDA_DEFAULT_ENV')" },
	},
})
