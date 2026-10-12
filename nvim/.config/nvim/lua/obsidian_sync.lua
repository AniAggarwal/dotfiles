local M = { running = false }
local root = "/home/ani/data/obsidian-vault"
local origin = "https://github.com/AniAggarwal/vault.git"

local function notify(message, level)
	vim.notify("Obsidian sync: " .. message, level or vim.log.levels.INFO)
end

local function paths(output)
	return vim.split(output, "\0", { plain = true, trimempty = true })
end

local function eligible(path)
	if path:match("^%.") or path:find("/%.") then
		return false
	end
	return path:match("%.md$") ~= nil or ("/" .. path):find("/attachments/", 1, true) ~= nil
end

local function buffers()
	local result = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
			local name = vim.api.nvim_buf_get_name(buf)
			local real = vim.uv.fs_realpath(name) or vim.fs.normalize(name)
			if real:sub(1, #root + 1) == root .. "/" then
				result[buf] = real:sub(#root + 2)
			elseif name:sub(1, #root + 1) == root .. "/" and vim.bo[buf].modified then
				error("Vault buffer points outside the vault: " .. name, 0)
			end
		end
	end
	return result
end

local function unchanged_buffers()
	for buf in pairs(buffers()) do
		if vim.bo[buf].modified then
			error("Unsaved vault edits appeared during sync; save them and retry. Nothing was discarded.", 0)
		end
	end
end

local function check_disk(buf)
	local changed = false
	local autocmd = vim.api.nvim_create_autocmd("FileChangedShell", {
		buffer = buf,
		callback = function()
			changed = true
			vim.v.fcs_choice = ""
		end,
	})
	local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
		vim.cmd("checktime")
	end)
	vim.api.nvim_del_autocmd(autocmd)
	if not ok then
		error(err, 0)
	end
	if changed then
		error("File changed outside Neovim; reconcile it before syncing: " .. vim.api.nvim_buf_get_name(buf), 0)
	end
end

local function refresh_buffers()
	for buf in pairs(buffers()) do
		if not vim.bo[buf].modified then
			local autoread = vim.bo[buf].autoread
			vim.bo[buf].autoread = true
			pcall(vim.api.nvim_buf_call, buf, function()
				vim.cmd("checktime")
			end)
			vim.bo[buf].autoread = autoread
		end
	end
end

local function conflicts()
	local ok, err = pcall(vim.cmd, "DiffviewOpen -C" .. vim.fn.fnameescape(root))
	if not ok then
		notify("Could not open Diffview: " .. tostring(err), vim.log.levels.ERROR)
	end
end

function M.sync()
	if M.running then
		notify("Already running.", vim.log.levels.WARN)
		return
	end
	M.running = true
	local lock
	local worker
	local function finish(err)
		if lock then
			vim.uv.fs_rmdir(lock)
		end
		M.running = false
		if err then
			notify(tostring(err), vim.log.levels.ERROR)
		end
	end
	local function resume(...)
		local ok, err = coroutine.resume(worker, ...)
		if not ok then
			finish(err)
		elseif coroutine.status(worker) == "dead" then
			finish()
		end
	end
	local function git(args, allow_failure)
		local argv = { "git", "--literal-pathspecs", "-C", root }
		vim.list_extend(argv, args)
		vim.system(argv, { text = false, timeout = 120000, env = { GIT_TERMINAL_PROMPT = "0" } }, function(result)
			vim.schedule(function()
				resume(result)
			end)
		end)
		local result = coroutine.yield()
		if result.code ~= 0 and not allow_failure then
			error(table.concat(args, " ") .. " failed:\n" .. (result.stderr or "") .. (result.stdout or ""), 0)
		end
		return result
	end
	local function output(args)
		return git(args).stdout
	end
	local function clean_index()
		if output({ "diff", "--cached", "--name-only", "-z" }) ~= "" then
			error("Index already contains staged changes; review/commit them before syncing.", 0)
		end
	end
	worker = coroutine.create(function()
		if vim.uv.fs_realpath(root) ~= root or vim.trim(output({ "rev-parse", "--show-toplevel" })) ~= root then
			error("Expected vault repository at " .. root, 0)
		end
		if
			vim.trim(output({ "symbolic-ref", "--short", "HEAD" })) ~= "main"
			or vim.trim(output({ "rev-parse", "--abbrev-ref", "@{upstream}" })) ~= "origin/main"
			or vim.trim(output({ "remote", "get-url", "origin" })) ~= origin
			or vim.trim(output({ "remote", "get-url", "--push", "origin" })) ~= origin
		then
			error("Expected main tracking origin/main at " .. origin, 0)
		end
		local gitdir = vim.trim(output({ "rev-parse", "--absolute-git-dir" }))
		local candidate = gitdir .. "/obsidian-sync.lock"
		if not vim.uv.fs_mkdir(candidate, 448) then
			error("Another sync owns " .. candidate .. "; if stale, inspect it before removing it.", 0)
		end
		lock = candidate
		for _, marker in ipairs({
			"MERGE_HEAD",
			"rebase-merge",
			"rebase-apply",
			"CHERRY_PICK_HEAD",
			"REVERT_HEAD",
			"sequencer",
			"index.lock",
		}) do
			if vim.uv.fs_stat(gitdir .. "/" .. marker) then
				if marker == "MERGE_HEAD" then
					conflicts()
				end
				error(
					"Git operation in progress (" .. marker .. "). Resolve/stage and finish it manually, then retry.",
					0
				)
			end
		end
		clean_index()
		if output({ "ls-files", "--others", "--exclude-standard", "-z" }) ~= "" then
			error(
				"Untracked vault files need review and explicit Git enrollment; sync never adds new files automatically.",
				0
			)
		end
		local tracked = {}
		for _, path in ipairs(paths(output({ "ls-files", "-z" }))) do
			tracked[path] = true
		end
		local vault_buffers = buffers()
		for buf, path in pairs(vault_buffers) do
			if vim.bo[buf].modified and (not tracked[path] or not eligible(path)) then
				error("Modified buffer is not an enrolled note/attachment: " .. path, 0)
			end
			check_disk(buf)
		end
		for buf in pairs(vault_buffers) do
			if vim.bo[buf].modified then
				vim.api.nvim_buf_call(buf, function()
					vim.cmd("update")
				end)
				if vim.bo[buf].modified then
					error("Could not save vault buffer.", 0)
				end
			end
		end
		local changed = paths(output({ "diff", "--name-only", "-z" }))
		for _, path in ipairs(changed) do
			if not tracked[path] or not eligible(path) then
				error("Unexpected dirty vault path; review it manually: " .. path, 0)
			end
		end
		unchanged_buffers()
		clean_index()
		if #changed > 0 then
			local args = { "add", "--" }
			vim.list_extend(args, changed)
			git(args)
			git({ "commit", "-m", "Sync Obsidian notes" })
		end
		unchanged_buffers()
		if output({ "status", "--porcelain", "--untracked-files=all" }) ~= "" then
			error("Vault changed during sync; inspect it and retry. Local commits are preserved.", 0)
		end
		notify("Pulling origin/main…")
		local pull = git({ "pull", "--no-rebase", "--no-edit", "--no-autostash", "origin", "main" }, true)
		refresh_buffers()
		if pull.code ~= 0 then
			if output({ "diff", "--name-only", "--diff-filter=U", "-z" }) ~= "" then
				conflicts()
				error(
					"Merge conflicts: push skipped. Resolve in Diffview, save/stage each file, finish the merge commit, then sync again.",
					0
				)
			end
			error("Pull failed; push skipped:\n" .. (pull.stderr or "") .. (pull.stdout or ""), 0)
		end
		unchanged_buffers()
		if output({ "status", "--porcelain", "--untracked-files=all" }) ~= "" then
			error("Vault changed during pull; push skipped. Inspect and retry.", 0)
		end
		notify("Pushing main…")
		git({ "push", "origin", "HEAD:refs/heads/main" })
		notify("Synced main with origin/main.")
	end)
	resume()
end

return M
