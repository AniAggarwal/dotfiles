# User Preferences

## Python Environment
- Use `micromamba` for conda/mamba environments (not conda or mamba)
- Use `uv` for Python package management and virtual environments

## CLI Tools
- Prefer `fd` over `find` for file searching
- Prefer `rg` (ripgrep) over `grep` for text searching

## Authorization
- Authorization for concrete work persists across turns and delegated work. Ask again only when targets, recipients, cost, destructive impact, or other material scope expands. Preserve unrelated work.
- Use the current session configuration or explicit request for model, effort, and service tier; do not store fixed model-selection rules.


## Messaging me
- `agent-inbox send "Title" <<'EOF' … EOF` puts a message in my bar inbox. The body is markdown, and LaTeX math (`$…$`, `$$…$$`) renders. Sender, project, branch and time are added automatically.
- Use it when I'm likely away and something needs me: long work finished, a decision that blocks you, or a result worth reading later. Add `--urgent` only when you're blocked on me.
- Not for routine progress. One message per finished piece of work, written to be read cold: lead with the outcome, then what I need to do, if anything.
