HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt extendedglob nomatch

# Using case insensitive completion
CASE_SENSITIVE="false"

# Autocorrect commands
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="false"

# Append to hist file rather than overwrite
setopt INC_APPEND_HISTORY
# Ignore duplicates when using up/down arrow
setopt HIST_FIND_NO_DUPS
# Don't add duplicates to hist file
setopt HIST_IGNORE_DUPS

# The following lines were added by compinstall
zstyle :compinstall filename '/home/ani/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ani/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ani/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ani/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ani/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


########################
###### Oh My Zsh #######
########################
export ZSH="$HOME/.oh-my-zsh"

# Not using theme as starship controls my prompt
ZSH_THEME=""

# Plugins
# TODO: decide if keeping python plugin
plugins=(
    git
    python
    sudo 
    # dirhistory # causing issues with clone-in-kitty so removed for now
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-vi-mode 
)


# source $ZSH/oh-my-zsh.sh
########################


# TODO: set up bat preview: https://github.com/junegunn/fzf#preview-window

########################
####### Keybinds #######
########################
# ctrl+enter is mapped to ctrl+space, enter in kitty config
# as work around to mapping ctrl+enter directly to autosuggest-execute
# Alt+L will clear screen, bound in kitty config rather than .zshrc

# jk to switch to command mode 
ZVM_VI_ESCAPE_BINDKEY=jk

# Switching between Insert and Normal mode have less timeout but not too low so that jk works
ZVM_KEYTIMEOUT=0.1

# run after init because zsh-vi-mode uses zvm instead of zle
function zvm_after_init() {
    # Use FZF's completion and keybinds
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh 

    bindkey '^ ' autosuggest-accept

    # Aliases
    if [ -f ~/.aliases ]; then
        . ~/.aliases
    fi
}

########################

# Add Conda autocomplete to path
fpath+=/opt/conda-zsh-completion

# Enable Conda autocomplete
compinit


# Use Neovim as default editor
export EDITOR="/usr/bin/nvim"

# Use Neovim for man pages
export MANPAGER='nvim +Man!'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Source oh-my-zsh at end to allow zsh-vi-mode keybinds to work
source $ZSH/oh-my-zsh.sh

# Set up starship prompt
eval "$(starship init zsh)"


export PATH=$PATH:/home/ani/.spicetify
