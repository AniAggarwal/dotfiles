# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt extendedglob nomatch
bindkey -v
# End of lines configured by zsh-newuser-install
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

# oh-my-zsh set up
export ZSH="$HOME/.oh-my-zsh"

# More themes link: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Using case insensitive completion
CASE_SENSITIVE="false"

# Autocorrect commands
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"


# Must define before zsh-vi-mode for these to work
bindkey '^ ' autosuggest-accept
# ctrl+enter is mapped to ctrl+space, enter in kitty config
# as work around to mapping ctrl+enter directly to autosuggest-execute

# Plugins
# TODO decide if keeping python plugin
plugins=(
    git
    python
    sudo 
    dirhistory
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-vi-mode 
)

source $ZSH/oh-my-zsh.sh

# jk to switch to command mode 
ZVM_VI_ESCAPE_BINDKEY=jk

# Alt+L will clear screen, bound in kitty config rather than .zshrc

# Switching between Insert and Normal mode have less timeout but not too low so that jk works
ZVM_KEYTIMEOUT=0.1

########################
###### Oh My Zsh #######
########################

########################
##### User Defined #####
########################

# Append to hist file rather than overwrite
setopt INC_APPEND_HISTORY
# Ignore duplicates when using up/down arrow
setopt HIST_FIND_NO_DUPS
# Don't add duplicates to hist file
setopt HIST_IGNORE_DUPS



# TODO: set up bat preview: https://github.com/junegunn/fzf#preview-window
# Use FZF's completion and keybinds
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add Conda autocomplete to path
fpath+=/opt/conda-zsh-completion

# Enable Conda autocomplete
compinit

# Aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Use Neovim as default editor
export EDITOR="/usr/bin/nvim"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

########################
##### User Defined #####
########################
