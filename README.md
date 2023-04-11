# My dotfiles
This repository contains my personal dotfiles. These dotfiles are used to configure and customize various aspects of my system.

## Installation

**NOTE:** The `setup.sh` script DOES NOT YET WORK. Once it does, the below instructions will be relevant.
To install these dotfiles, run the setup.sh script provided in the repository:

```bash
./setup.sh
```
This script will symlink the dotfiles in this repository to their respective locations in the home directory. Please make sure to backup any existing configuration files before running this script.

## Contents
- `README.md`: repository description
- `LICENSE`: repository license
- `setup.sh`: script to set up dotfiles
- `change-brightness`: scripts to change screen brightness
- `.config`: various configuration files
    - `.aliases`: contains aliases for the zsh shell
    - `auto-cpufreq.conf`: configuration file for the `auto-cpufreq` tool which automatically changes the CPU frequency based on usage
    - `bat`: contains configuration file and theme for the `bat` command-line tool, which is a replacement for `cat` with syntax highlighting and git integration
    - `easyeffects`: contains configuration files for the `easyeffects` audio processing application, which provides a graphical interface for PulseEffects
    - `.fdignore`: specifies patterns to be ignored by the `fd` command-line tool, which is a replacement for `find`
    - `grub`: contains custom configuration files for the GRUB bootloader
    - `kitty`: contains configuration files for the `kitty` terminal emulator, including a custom theme and key mappings
    - `libinput-gestures.conf`: configuration file for the `libinput-gestures` tool which enables gesture support for touchpads and other input devices
    - `nvim`: contains configuration files and plugins for the `neovim` text editor, including language-specific configurations, plugins, and key mappings
    - `qtile-startup.sh`: script that launches programs when the `qtile` window manager starts up
    - `starship.toml`: configuration file for the `starship` prompt, a minimal and fast shell prompt
    - `.zshrc`: configuration file for the `zsh` shell
