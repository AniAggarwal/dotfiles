#!/usr/bin/bash

dir=~/dotfiles

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -a, --all           Install all dotfiles, excluding those that require sudo"
    echo "  -s, --sudo          Install only dotfiles that require sudo"
    echo "  -d, --dir DIR       Directory where the dotfiles are installed (default: ~/dotfiles)"
    echo "  -h, --help          Display this help message"
}

install_all_no_sudo() {
    stow -d "$dir" -t ~/ zsh kitty nvim bat conky easyeffects ignores bin hyprland swaylock-effects spotify-launcher rofi brave wireplumber
}

install_all_sudo() {
    sudo stow -d "$dir" -t /etc/ battery-optimizations
    sudo stow -d "$dir" -t /usr/share/grub/themes/ grub-theme
}

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -a|--all)
            install_all_no_sudo
            echo "Note: battery-optimizations and grub-theme require sudo, skipping installation."
            ;;

        -s|--sudo)
            install_all_sudo
            ;;

        -d|--dir)
            dir="$2"
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
    shift
done
