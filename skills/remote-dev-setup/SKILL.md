---
name: remote-dev-setup
description: Set up or repair Ani's Python development environment on a remote SSH machine using a targeted clone of public GitHub dotfiles, Neovim, Zsh vi mode, and CLI tools. Use when preparing an SSH host for interactive development or restoring this setup on an existing host.
---

# Remote development setup

Prepare the user's account on an SSH-accessible machine for editing and running Python projects directly there. Default to the full Neovim configuration and portable shell conveniences. Adapt installations to the remote OS and architecture; Linux is the established path, not a requirement. Use the user's existing SSH access method, including ports, jump hosts, proxy commands, or provider-specific tunnels. Do not assume GCP.

## Inspect before changing

- Establish the target host/account from the request or existing SSH context. Ask only when the destination is ambiguous. Verify identity, home directory, OS, architecture, libc where relevant, available disk space, sudo access, shell, and existing tools/config.
- Read applicable remote `AGENTS.md` and inspect the public Neovim config's requirements. Inspect shell files selectively without dumping secrets.
- Reuse working tools. Install into the user's account where practical; use system packages for dependencies when authorized sudo is available. Without sudo, use compatible user-scoped binaries or builds and report unavoidable gaps.
- Back up existing config files or symlinks before replacing them. Preserve unrelated shell settings, credentials, and project environments. Reruns must not append duplicate blocks, reset dirty clones, or overwrite existing config without examining it.
- Use `uv` for Python packages/venvs and `micromamba` for conda environments. Prefer `rg` and `fd` for searching.

## Public source only

Default source: `https://github.com/AniAggarwal/dotfiles.git`, branch `main`. Use a user-specified ref if given; record the deployed commit.

**Never upload the local dotfiles working tree, home directory, credentials, shell secrets, or local plugin caches.** Deploy only committed content fetched from the public repository. Do not commit unrelated local modifications to make them available remotely. Do not run the repository's whole desktop installer on a server.

On a new target, make a sparse clone under `~/.local/share/dotfiles` (adjust if occupied):

```sh
git clone --depth 1 --filter=blob:none --sparse --branch main \
  https://github.com/AniAggarwal/dotfiles.git "$HOME/.local/share/dotfiles"
git -C "$HOME/.local/share/dotfiles" sparse-checkout set nvim/.config/nvim
git -C "$HOME/.local/share/dotfiles" rev-parse HEAD
```

Cone-mode sparse checkout also includes some ancestor/root files; the deployment allowlist remains only `nvim/.config/nvim`. After backup, symlink `~/.config/nvim` to that directory. Fetch public upstream on the remote for updates, inspect any local changes, and update only a clean managed clone with a fast-forward. Do not use `reset --hard`, `clean`, or forced replacement to resolve drift. Follow the same backup rules if XDG directories are customized.

For shell aliases or settings, inspect committed `zsh/.aliases` and `zsh/.zshrc` from that fetched repository (`git show HEAD:zsh/.aliases`); extend the sparse checkout only if needed. Extract portable pieces. Do not source the entire desktop `.zshrc`, `.aliases`, or install script: these contain machine paths, desktop programs, and distro-specific commands. Public source still needs inspection for host compatibility and sensitive content before activation.

## Tools and Neovim

Install or verify:

- Neovim compatible with the checked-out config; Git, curl, archive tools, and compiler/build tools for native plugins.
- `rg`, `fd`, `fzf`, `eza`, Zsh, `uv`, micromamba, and a supported Node runtime for language tools. Ubuntu's `fdfind` may need a user-scoped `fd` symlink. Install lazygit if enabling its alias.
- Other runtime dependencies actually needed by the configured plugins, such as image libraries or `libsecret`; distinguish optional desktop features from Python essentials.

Consult official installation sources for current versions and commands. Select the correct architecture/libc asset. A version label alone does not prove compatibility: run each binary. On older glibc, prefer a compatible release, musl build, or source build. Tree-sitter CLI 0.25.10 worked on Ubuntu 22.04 in the original setup; newer release binaries required newer glibc. Check the current plugin's CLI requirements before using that fallback.

Create a dedicated provider/debugger environment, separate from project dependencies:

```sh
uv venv --python 3.12 "$HOME/.local/share/nvim/python"
uv pip install --python "$HOME/.local/share/nvim/python/bin/python" pynvim debugpy
```

Reuse an existing compatible environment rather than replacing it. Honor a requested Python version. The public config should resolve the provider and debug adapter through `stdpath("data") .. "/python/bin/python"`; verify the fetched revision rather than assuming this remains true.

Restore plugins with the checked-in `lazy-lock.json` (Lazy restore, not an unrequested upgrade). Wait for asynchronous installation/build jobs to finish. Install all configured Mason language servers and formatters, Tree-sitter parsers, and Telescope's native fzf extension. Confirm executables exist and launch; registry entries alone are insufficient evidence. Python defaults are BasedPyright for language features/type checking, Ruff for lint/formatting, and debugpy for debugging. Preserve the config's choice to leave experimental servers manually enabled.

Confirm new interactive and login shells have the tools on PATH. Avoid depending on temporary PATH exports in setup commands.

## Remote behavior

- Enable Neovim OSC52 clipboard support for SSH sessions when supported by the installed Neovim. Real transmission requires a terminal check; configuration alone is not proof.
- Guard unavailable local Herdr/Kitty pane scripts and hardcoded Python paths. Prefer already committed portability fixes. If new fixes are needed, keep them narrow and reviewable; preserve a clean upstream clone by tracking any remote-specific overlay separately.
- Use `kitten ssh <host>` from Kitty for remote terminfo and shell integration; ordinary SSH remains usable. Kitty configuration is local. Do not install a full remote desktop or assume remote control/pane crossing works without testing it.
- Never disable SSH host-key verification to simplify setup. Reuse existing trust and access configuration. Provider-specific identity refresh remains separate from installing the editor.

## Zsh and aliases

Install `jeffreytse/zsh-vi-mode` from its public upstream. Configure before sourcing the plugin:

```zsh
function zvm_config() {
    ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
    ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
    ZVM_KEYTIMEOUT=0.1
    ZVM_VI_HIGHLIGHT_BACKGROUND='#3e4452'
    ZVM_VI_HIGHLIGHT_FOREGROUND='#abb3be'
}
```

Set **`ZVM_VI_INSERT_ESCAPE_BINDKEY` explicitly**. Setting only `ZVM_VI_ESCAPE_BINDKEY` inside the callback does not update the Insert-mode value initialized earlier. Keep Escape available. Source the installed plugin, initialize completion/history, and set `EDITOR`/`VISUAL` to Neovim.

Restore portable aliases from the public revision: especially `l`, `ll`, `ls`, `tree`, `nconf`, and micromamba shortcuts. Ensure each target command exists; skip/report unavailable optional aliases. Adapt Kitty aliases to `kitten` when that is the available remote entry point. Do not overwrite unrelated existing aliases. Add autosuggestions, syntax highlighting, or prompt plugins when requested or part of the desired shell scope.

Keep existing environment exports available in Zsh without displaying their values or sourcing Bash-specific startup logic wholesale. Never copy local secrets or run access-token printing commands. If extracting existing remote exports into a shared file, keep it account-readable only and avoid automatically executing credential-producing commands.

Use `chsh` when the account supports it and changing the login shell is within scope. For externally managed accounts that reject `chsh`, add an idempotent interactive SSH-only Bash-to-Zsh handoff **after existing environment initialization**:

```bash
if [[ $- == *i* && -n ${SSH_CONNECTION:-} && -z ${ZSH_VERSION:-} ]]; then
    exec /usr/bin/zsh
fi
```

Use the actual installed Zsh path. Leave noninteractive SSH commands working. Back up startup files and verify syntax before activating changes.

## Coding assistants

For a full setup, install Claude Code and Codex user-scoped using current official instructions, unless the user excludes them. Verify version/help commands and fresh-login PATH. Authentication is a separate user action; do not copy local tokens or run an agent against projects as an installation test. Provide the installed version's SSH-friendly login commands. API demos, cloud SDKs, model calls, and project changes are optional user requests, not default setup steps.

## Verify before reporting completion

Use an isolated temporary Python project with `pyproject.toml` and a uv `.venv`. Avoid a loose file outside a project root, which may not start the LSP. Check:

- Actual Neovim startup; plugin/runtime errors, provider initialization, Python Tree-sitter, completion configuration, and native Telescope fzf.
- BasedPyright and Ruff attach; type/diagnostic response and a real Ruff buffer-format operation.
- Debugger uses the project interpreter, hits a breakpoint, continues, and exits cleanly.
- Interactive SSH shell enters Zsh; actual `jk` keystrokes enter Normal mode and a subsequent editing motion works. Checking a variable or binding alone is insufficient. Test `l` and the other installed aliases.
- Fresh-login PATH; noninteractive SSH still executes a simple command successfully.
- Clipboard and Kitty graphics/pane integration when an appropriate real terminal is available. Otherwise explicitly label these unverified.

Do not use broad process cleanup such as `pkill nvim`; stop only setup-owned processes. Do not use occupied GPUs or run workloads as part of editor verification. If a required tool or check remains blocked, report the exact gap rather than calling the environment fully working.

Finish with connection/start commands, deployed public commit, tool versions, verification results, backup/rollback paths, and any remaining login or terminal checks. Provide the update command for the clean sparse clone; do not promise automatic configuration sync.
