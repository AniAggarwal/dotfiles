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


# TODO parse arugments for which things to configure
# TODO make it install Fira Code Nerd Font
setup_kitty
