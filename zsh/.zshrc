# Time startup speed
# zmodload zsh/zprof

# Source Zap Plugin Manager
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

###########
# Options #
###########

# remove / so that ctrl+w deletes only to /
# original: WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
# Using case insensitive completion
CASE_SENSITIVE="false"
# Autocorrect commands
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="false"

export EDITOR="/usr/bin/nvim"
export PATH="$HOME/bin:$PATH"
export PATH=$PATH:/home/ani/.spicetify
export MAMBA_ROOT_PREFIX=/home/ani/micromamba

# Append to hist file rather than overwrite
setopt INC_APPEND_HISTORY
# Ignore duplicates when using up/down arrow
setopt HIST_FIND_NO_DUPS
# Don't add duplicates to hist file
setopt HIST_IGNORE_DUPS
# Use #, ~, ^ as patterns. Raise error if no match
setopt extendedglob nomatch
# Allow tab completion on hidden files
setopt globdots
# Highlight matches when completing
zstyle ':completion:*' menu select

# Show hidden files when completing
_comp_options+=(globdots)

# Try searching history before using zsh's completion
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# TODO: wait util PR is merged to vi-mode for system clipboard

####################
# Custom Functions #
####################

# FZF
function fzf_config {
    # If slow performance, remove --ansi, --color always, and whole exa command
    FZF_PREVIEW="bat --color always {} || exa --all --sort=type --tree --level 3 --color-scale {}"
    FZF_FIND="fd --hidden --strip-cwd-prefix --exclude micromamba --exclude .git --color always"
    export FZF_DEFAULT_COMMAND="$FZF_FIND"
    export FZF_DEFAULT_OPTS="--ansi"

    export FZF_CTRL_T_COMMAND="$FZF_FIND"
    export FZF_CTRL_T_OPTS="--preview '($FZF_PREVIEW) 2> /dev/null' --bind 'ctrl-/:change-preview-window(down|hidden|)'"

    export FZF_CTRL_R_OPTS="
    --preview 'echo {}' --preview-window up:3:hidden:wrap
    --bind 'ctrl-/:toggle-preview'
    --color header:italic
    --header 'Press CTRL-/ to show full command.'"

    export FZF_ALT_C_COMMAND="$FZF_FIND --type d"
    export FZF_ALT_C_OPTS="--preview 'tree -C {}'"
}

function fzf_open_file {
    local file
    { file="$(fzf)" && [ -f "$file" ] && xdg-open "$file" &> /dev/null } </dev/tty
}


##################
# Plugin Configs #
##################

# zsh-vi-mode config. Not using zvm_opts because it is not working
# Must be manually set before sourcing zsh-vi-mode
function zvm_before_init_opts() {
    # Use the better key engine
    ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX
    # Use insert mode by default
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
    # jk to switch to command mode
    ZVM_VI_ESCAPE_BINDKEY=jk
    # Switching between Insert and Normal mode have less timeout but not too low so that jk works
    ZVM_KEYTIMEOUT=0.1

    # Change highlight colors
    ZVM_VI_HIGHLIGHT_BACKGROUND=#3e4452
    ZVM_VI_HIGHLIGHT_FOREGROUND=#abb3be
}

# Fix compatibility issues with zsh-vi-mode
function zvm_after_init() {
    # Use FZF's completion and keybinds
    [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
    [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
    fzf_config

    # Cycle backwards through completion suggestions
    bindkey '^[[Z' reverse-menu-complete

    # Ctrl+space to accept suggestion, ctrl+enter to acecpt, execute
    bindkey '^ ' autosuggest-accept
    # TODO: execute doesn't work, using kitty workaround for now
    # bindkey '^\n' autosuggest-execute

    # Ctrl+o to open file using fzf
    zvm_define_widget fzf_open_file
    bindkey '^o' fzf_open_file

    # Aliases
    if [ -f ~/.aliases ]; then
        . ~/.aliases
    fi
}


#############################
# Autogenerated Code Blocks #
#############################

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE='/usr/bin/micromamba';
export MAMBA_ROOT_PREFIX='/home/ani/micromamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<


### opam configuration ###
# Auto generated is below, but we are prefering our own eval
# [[ ! -r /home/ani/.opam/opam-init/init.zsh ]] || source /home/ani/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null
# opam recomends: eval $(opam env) but cliff recommends below
eval `opam config env`

###########
# Plugins #
###########
plug "zsh-users/zsh-autosuggestions"
zvm_before_init_opts ; plug "jeffreytse/zsh-vi-mode"
plug "zsh-users/zsh-syntax-highlighting"

###################
# Starship prompt #
###################

eval "$(starship init zsh)"


#############
# SSH Agent #
#############

# TODO: do I need this?

# if ! pgrep -u "$USER" ssh-agent > /dev/null; then
#     ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
# fi
#
# if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
#     source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
# fi

# Completes measurement of zsh startup speed
# zprof
