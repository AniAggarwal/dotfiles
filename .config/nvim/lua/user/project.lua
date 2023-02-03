require("project_nvim").setup({
	-- add .project and .classpath to defaults for Eclipse projects
	patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", ".project", ".classpath" },
})
