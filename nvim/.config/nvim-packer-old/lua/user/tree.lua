local function on_attach(bufnr)
	local api = require("nvim-tree.api")

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

    api.config.mappings.default_on_attach(bufnr)

	-- Mappings removed:
    vim.keymap.set("n", "<C-x>", "", { buffer = bufnr })
	vim.keymap.del("n", "<C-x>", { buffer = bufnr })

    -- Added
	vim.keymap.set("n", "<C-s>", api.node.open.horizontal, opts("Open: Horizontal Split"))
end



require("nvim-tree").setup({
	disable_netrw = true,

	diagnostics = {
		enable = true,
	},

    -- Add custom keybinds
    on_attach = on_attach,

	-- for syncing with project_nvim
	sync_root_with_cwd = true,
	respect_buf_cwd = true,
	update_focused_file = {
		enable = true,
		update_root = true,
	},
})

local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- create a new, empty buffer
	vim.cmd.enew()

	-- wipe the directory buffer
	vim.cmd.bw(data.buf)

	-- change to the directory
	vim.cmd.cd(data.file)

	-- open the tree
	require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
