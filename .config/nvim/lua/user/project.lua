local status_ok, project = pcall(require, "project_nvim")
if not status_ok then
	return
end
project.setup({
    -- add .project and .classpath to defaults for Eclipse projects
	patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", ".project", ".classpath" },
})
