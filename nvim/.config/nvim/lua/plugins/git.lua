-- Fetch a PR into its own worktree and open it for review. Uses the
-- pull/N/head ref rather than a branch name so PRs from forks work too.
local function pr_worktree(number)
	local function git(args)
		local out = vim.fn.system("git " .. args)
		if vim.v.shell_error ~= 0 then
			error(out)
		end
		return vim.trim(out)
	end

	local ok, err = pcall(function()
		local root = git("rev-parse --show-toplevel")
		local base = vim.trim(vim.fn.system("gh pr view " .. number .. " --json baseRefName -q .baseRefName"))
		if vim.v.shell_error ~= 0 then
			error("gh pr view failed: " .. base)
		end

		local path = vim.fs.joinpath(vim.fs.dirname(root), vim.fs.basename(root) .. "-pr-" .. number)
		local branch = "pr-" .. number

		if vim.fn.isdirectory(path) == 0 then
			git(("fetch origin +refs/pull/%s/head:refs/remotes/origin/pr/%s %s"):format(number, number, base))
			git(("branch -f %s origin/pr/%s"):format(branch, number))
			git(("worktree add %s %s"):format(vim.fn.shellescape(path), branch))
		end

		vim.cmd.tcd(path)
		vim.cmd.edit(path)
		vim.cmd("DiffviewOpen origin/" .. base .. "...HEAD")
		vim.notify(("PR #%s in %s (vs %s)"):format(number, path, base), vim.log.levels.INFO)
	end)

	if not ok then
		vim.notify("PR worktree failed: " .. tostring(err), vim.log.levels.ERROR)
	end
end

local function pick_pr_worktree()
	local raw = vim.fn.system("gh pr list --limit 50 --json number,title,author")
	if vim.v.shell_error ~= 0 then
		vim.notify("gh pr list failed: " .. raw, vim.log.levels.ERROR)
		return
	end
	local prs = vim.json.decode(raw)
	if #prs == 0 then
		vim.notify("No open PRs", vim.log.levels.WARN)
		return
	end
	vim.ui.select(prs, {
		prompt = "PR → worktree",
		format_item = function(pr)
			return ("#%d  %s  (@%s)"):format(pr.number, pr.title, pr.author.login)
		end,
	}, function(pr)
		if pr then
			pr_worktree(pr.number)
		end
	end)
end

local function pick_worktree()
	local lines = vim.fn.systemlist("git worktree list")
	if vim.v.shell_error ~= 0 then
		vim.notify("Not in a git repo", vim.log.levels.ERROR)
		return
	end
	vim.ui.select(lines, { prompt = "Worktree" }, function(line)
		if not line then
			return
		end
		local path = vim.split(line, "%s+")[1]
		vim.cmd.tcd(path)
		vim.cmd.edit(path)
	end)
end

vim.api.nvim_create_user_command("PrWorktree", function(o)
	if o.args ~= "" then
		pr_worktree(o.args)
	else
		pick_pr_worktree()
	end
end, { nargs = "?", desc = "Check out a PR into a worktree and review it" })

return {

	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		cmd = "Neogit",
		keys = {
			{ "<leader>gg", "<cmd>Neogit<CR>", desc = "Neogit status" },
			{ "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Neogit commit" },
		},
		opts = {
			-- kitty draws the graph with the graphics protocol; fall back to
			-- unicode over ssh or in other terminals.
			graph_style = vim.env.TERM == "xterm-kitty" and "kitty" or "unicode",
			process_spinner = true,
			commit_editor = {
				staged_diff_split_kind = "vsplit",
			},
			-- without this the branch/commit pickers use the slow default sorter
			telescope_sorter = function()
				return require("telescope").extensions.fzf.native_fzf_sorter()
			end,
			integrations = {
				diffview = true,
				telescope = true,
			},
		},
		config = function(_, opts)
			require("neogit").setup(opts)

			local group = vim.api.nvim_create_augroup("UserNeogitStatusMappings", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = "NeogitStatus",
				callback = function(event)
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(event.buf) then
							return
						end

						local function open_diff()
							local status = require("neogit").status.instance()
							if not status or not status.buffer or status.buffer.handle ~= event.buf then
								return
							end

							local item = status.buffer.ui:get_item_under_cursor()
							local section = status.buffer.ui:get_selection().section
							if not item or not item.name or not section or not section.name then
								return
							end

							require("neogit.integrations.diffview").open(section.name, item.name, { only = true })
						end

						vim.keymap.set("n", "<S-CR>", open_diff, { buffer = event.buf, desc = "Open file in Diffview" })
					end)
				end,
			})
		end,
	},

	{
		"rbong/vim-flog",
		dependencies = { "tpope/vim-fugitive" },
		cmd = { "Flog", "Flogsplit", "Floggit" },
		keys = {
			{ "<leader>gl", "<cmd>Flog<CR>", desc = "Git graph (this branch)" },
			{ "<leader>gL", "<cmd>Flog -all<CR>", desc = "Git graph (all branches)" },
			-- Branch topology only: --simplify-by-decoration keeps commits that
			-- carry a ref, plus the merges needed to connect them.
			{
				"<leader>gb",
				"<cmd>Flog -all -raw-args=--simplify-by-decoration -format=[%h]%d\\ %s<CR>",
				desc = "Git graph (branches only)",
			},
		},
	},

	{
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		cmd = "Octo",
		keys = {
			{ "<leader>gP", "<cmd>Octo pr list<CR>", desc = "List PRs" },
			{ "<leader>gI", "<cmd>Octo issue list<CR>", desc = "List issues" },
			{ "<leader>gW", "<cmd>PrWorktree<CR>", desc = "PR → worktree + review" },
			{ "<leader>gw", pick_worktree, desc = "Switch worktree" },
		},
		opts = {
			picker = "telescope",
			use_local_fs = true,
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "󰐊" },
				topdelete = { text = "󰐊" },
				changedelete = { text = "▎" },
			},
			preview_config = {
				border = "rounded",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		},
		keys = {
			{ "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage hunk" },
			{ "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset hunk" },
			{ "<leader>gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage buffer" },
			{ "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<CR>", desc = "Undo stage hunk" },
			{ "<leader>gB", "<cmd>Gitsigns blame_line full=true<CR>", desc = "Blame line" },
			{ "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview hunk" },
			{ "<leader>gq", "<cmd>Gitsigns setqflist<CR>", desc = "Quickfix list" },
			{ "<leader>gdd", "<cmd>Gitsigns diffthis<CR>", desc = "Diff this" },
			{ "<leader>gdg", "<cmd>diffget<CR>", desc = "Diff get" },
			{ "<leader>gdp", "<cmd>diffput<CR>", desc = "Diff put" },

			{ "]h", "<cmd>Gitsigns nav_hunk next<CR>", desc = "Next Git Hunk" },
			{ "[h", "<cmd>Gitsigns nav_hunk prev<CR>", desc = "Previous Git Hunk" },
		},
	},

	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gD", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
			{ "<leader>D", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle Diffview" },
		},
		config = function()
			local actions = require("diffview.actions")
			require("diffview").setup({
				enhanced_diff_hl = true,
				file_panel = {
					win_config = {
						type = "split",
						position = "bottom",
						height = 10,
					},
				},
				keymaps = {
					-- `q` closes the whole view from anywhere inside it, matching
					-- how q behaves in Neogit and Flog. The help/option sub-panels
					-- keep their own q, which closes just the sub-panel.
					view = {
						{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
					},
					file_panel = {
						{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
					},
					file_history_panel = {
						{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
					},
					diff3 = {
						{ { "n", "x" }, "<leader>do", actions.diffget("ours"), { desc = "Diffget from OURS" } },
						{ { "n", "x" }, "<leader>dt", actions.diffget("theirs"), { desc = "Diffget from THEIRS" } },
					},
					diff4 = {
						{ { "n", "x" }, "<leader>db", actions.diffget("base"), { desc = "Diffget from BASE" } },
						{ { "n", "x" }, "<leader>do", actions.diffget("ours"), { desc = "Diffget from OURS" } },
						{ { "n", "x" }, "<leader>dt", actions.diffget("theirs"), { desc = "Diffget from THEIRS" } },
					},
				},
			})
		end,
	},
}
