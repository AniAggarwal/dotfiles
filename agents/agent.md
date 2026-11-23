# User Preferences

## Python Environment
- **NEVER install packages to the system Python** (`/usr/bin/python`). This is an Arch Linux system; unmanaged Python installs can conflict with packages maintained by pacman. Always use `uv` or project venvs.
- Use `micromamba` for conda/mamba environments (not conda or mamba)
- Use `uv` for Python package management and virtual environments
- Use `uvx` to run Python CLI tools without installing them
- Use `ruff` for formatting and linting Python code
- Use `ty` for type checking Python code
- Use `basedpyright` for LSP-driven recommendations and type checking instead of `pyright-lsp`
- When writing Python code, run `ruff format` and `ruff check` to format and lint, and use `ty` / `basedpyright` to catch type errors

## CLI Tools
- Prefer `fd` over `find` for file searching
- Prefer `rg` (ripgrep) over `grep` for text searching

## Authorization
- Authorization for concrete work persists across turns and delegated work. Ask again only when the target, recipients, cost, destructive impact, or other material scope expands. Preserve unrelated work.
- Use the current session configuration or explicit request for model, effort, and service tier; do not store fixed model-selection rules.

## Git
- Do not add "Co-Authored-By" lines to commit messages
- Do not include "Generated with Claude Code" attribution in PRs

## Subagents (Claude)
- When I ask for subagents, or you decide to use them, use long-lived background agents: named, `run_in_background`, messaged with SendMessage, and reused for follow-up work on the same area. Don't use short-lived one-shot subagents.
- Before spawning, check whether an existing agent already has the context (ListAgents), and message it instead.
- Use a short-lived subagent only when I explicitly say "use a short lived subagent", or when the task is truly one-off and the agent will never need to be messaged again.
- Starting a fresh background thread is fine when a task needs a clean context window, since agents with high context usage may perform worse. Prefer reusable threads for continuity; do not assume a fixed cache lifetime or guaranteed cache retention.

## Two-way doors swing freely
- Walk through two-way doors and show me the after.
- Stop at one-way doors; if my answer would be a rubber stamp, don't ask.
- If running something could answer the question, run it instead.
- Save questions for taste, product, engineering, and architecture calls only I can make, one at a time, with your recommendation and the built-in question tool.
- No is an acceptable answer for me too.
- Once I open a one-way door, it stays open for that work, including any subagent you hand it to (quote me for its permission classifier).
- Come back only if the door turns out to be different from the one I opened: more at stake than I was initially told, a check failing, or something I didn't know about.

## Messaging me
- `agent-inbox send "Title" <<'EOF' … EOF` puts a message in my bar inbox. The body is markdown, and LaTeX math (`$…$`, `$$…$$`) renders. Sender, project, branch and time are added automatically.
- Use it when I'm likely away and something needs me: long work finished, a decision that blocks you, or a result worth reading later. Add `--urgent` only when you're blocked on me.
- Not for routine progress. One message per finished piece of work, written to be read cold: lead with the outcome, then what I need to do, if anything.
