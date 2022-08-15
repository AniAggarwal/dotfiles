#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

setup_kitty() {
    KITTY_CONFIG_PATH="$HOME/.config/kitty"

    # Symlinking .config folders in .config to ~/.config
    if [ -d $KITTY_CONFIG_PATH ]; then
        mv "$KITTY_CONFIG_PATH" "$KITTY_CONFIG_PATH.backup"
    fi
    ln -s "$SCRIPT_DIR/.config/kitty" "$KITTY_CONFIG_PATH"

    # TODO add new kitty logo to kitty.desktop file
    # Make it install kitty, symlink it, add desktop file, etc.
    # Details: https://sw.kovidgoyal.net/kitty/binary/ 


}


setup_nvim() {

    # wget -P "$SCRIPT_DIR/" "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    # chmod u+x "$SCRIPT_DIR/nvim.appimage"

    # may not have to do the next two, depends on distro
    # "$SCRIPT_DIR/nvim.appimage" --appimage-extract
    # mv "$PWD/squashfs-root/" /opt/nvim/

    # May have to first make ~/.local/bin folder
    # ln -s /opt/nvim/AppRun /usr/bin/nvim

    # ln -s "$SCRIPT_DIR/.config/nvim/" "$HOME/.config/nvim"

    # sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    # Create conda env
    # ln ~/.config/nvim or whatever

    # Run PlugInstall to install plugins (or modify if switching to Lua later)
    # Coc - 
    # Tree sitter
    # rnvimr


}

setup_zsh() {
    sudo apt install zsh
    chsh -s $(which zsh)
    ln -s "$SCRIPT_DIR/.config/.zshrc" "$HOME/.zshrc"
    ln -s "$SCRIPT_DIR/.config/.aliases" "$HOME/.aliases"
    
    # Oh My Zsh
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # Autocomplete plugin
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/jeffreytse/zsh-vi-mode $ZSH_CUSTOM/plugins/zsh-vi-mode
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

}

setup_conda() {
    # install dir: https://docs.conda.io/en/latest/miniconda.html#linux-installers
    # bash minoconda3-latest-linux-...-.sh

    sudo git clone https://github.com/esc/conda-zsh-completion /opt/conda-zsh-completion
}


setup_apts() {
    # Make this walk through to decide what to install
    sudo apt install powertop
    sudo apt install btop
    sudo apt install tree

    # fzf, ranger, icat, etc.

    sudo apt install bat
    ln -s /usr/bin/batcat $HOME/.local/bin/bat
}


setup_fzf() {
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
}

setup_font() {
    # https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    # ls | grep '.*Windows.*\.ttf' | xargs -d"\n" rm
    # ls | grep -P '^((?!Mono).)*$' | xargs -d"\n" rm
    # ls | grep '.*Fura.*' | xargs -d"\n" rm
    # ls | grep '.*Retina.*' | xargs -d"\n" rm
    # mkdir -p ~/.local/share/fonts
    # move stuff to that ^ folder
    # fc-cache -f -v
    # confirm it work: fc-list | grep "Fira"
    # remove original unpacked dir and zip files


}


# TODO parse arugments for which things to configure
# TODO make it install Fira Code Nerd Font and make kitty use it
# TODO make an installation walk through to choose what all to install
# TODO grub/plymouth setup
# TODO python setup
# ZSH setup

setup_kitty
setup_apts
