#!/usr/bin/bash

dir=~/dotfiles

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -s, --no-sudo       Install dotfiles that don't require sudo"
    echo "  -a, --all           Install all dotfiles, including those that require sudo"
    echo "  -d, --dir DIR       Directory where the dotfiles are installed (default: ~/dotfiles)"
    echo "  -h, --help          Display this help message"
}

install_all_no_sudo() {
    stow -d "$dir" -t ~/ shell kitty nvim bat conky easyeffects ignores
}

install_all_sudo() {
    sudo stow -d "$dir" -t /etc/ battery-optimizations
    sudo stow -d "$dir" -t /usr/share/grub/themes/ grub-theme
}

install_all() {
    install_all_no_sudo
    install_all_sudo
}


while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -s|--no-sudo)
        install_all_no_sudo
        echo "Note: battery-optimizations and grub-theme require sudo, skipping installation."
        ;;

        -a|--all)
        install_all
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
