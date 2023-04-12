# My dotfiles
This repository contains my personal dotfiles. These dotfiles are used to configure and customize various aspects of my system.

## Installation

First, you must install `stow`. Once you clone the repository, just run the `install_dotfiles.sh` file.

```bash
git clone https://github.com/AniAggarwal/dotfiles
cd dotfiles/
./install_dotfiles.sh
```
## Usage of the install_dotfiles.sh script
```
install_dotfiles.sh [-s|--no-sudo] [-a|--all] [-d|--dir DIR] [-h|--help]
-s|--no-sudo: installs dotfiles that do not require sudo permissions
-a|--all: installs all dotfiles, including those that require sudo permissions
-d|--dir DIR: specifies the directory where the dotfiles are installed. The default is ~/dotfiles.
-h|--help: displays usage information and exits
```
To use the script, navigate to the directory containing the script in the terminal and execute the desired option. For example, to install all dotfiles including those that require sudo permissions, run:

```bash
./install_dotfiles.sh --all
```

To install only the dotfiles that do not require sudo permissions, run:
```bash
./install_dotfiles.sh --no-sudo
```

To specify a custom directory where the dotfiles are installed, rather than the assumes `~/dotfiles`, run:
```bash
./install_dotfiles.sh --dir /path/to/dotfiles
```

To display usage information, run:
`./install_dotfiles.sh --help`

**NOTE:**
- Make sure to back up your files before you run this script. If files are
  already found where stow tries to sym link them, it should stop and error.
  Backup and then delete those files and retry.
- The `setup.sh` script DOES NOT YET WORK. I am migrating from it to stow.

## Contents of dotfiles Directory
==============================

bat/: configuration files for the bat command line tool.

.config/bat/config: configuration file for bat.
.config/bat/themes/onedark.tmTheme: color scheme for bat.

battery-optimizations/: configuration file for auto-cpufreq which is used to optimize CPU performance based on battery life.

brightness-scripts/: scripts for controlling screen brightness.

.local/bin/decrease-brightness.sh: script for decreasing screen brightness.
.local/bin/increase-brightness.sh: script for increasing screen brightness.
.local/bin/toggle-low-brightness.sh: script for toggling between low and high screen brightness.

conky/: configuration files for conky, a system monitor tool.

.config/conky/Sirius/: configuration files for Sirius conky theme.

easyeffects/: configuration files for EasyEffects, an audio processing tool.

.var/app/com.github.wwmm.easyeffects/config/easyeffects/output/Custom Laptop.json: custom preset for laptop audio output.
.var/app/com.github.wwmm.easyeffects/config/easyeffects/output/xps-copied-preset.json: custom preset for XPS audio output.

grub-theme/: directory for custom grub themes.

ignores/: files and directories to be ignored by fd.

.fdignore: file containing patterns to ignore while searching using fd.

kitty/: configuration files for kitty, a terminal emulator.

.config/kitty/gnome-terminal-theme.conf: configuration file for gnome-terminal-theme.
.config/kitty/kitty.conf: configuration file for kitty.
.config/kitty/neighboring_window.py: Python script to open neighboring window.
.config/kitty/onedark-theme.conf: color scheme file for onedark theme.
.config/kitty/pass_keys.py: script to pass keystrokes to neighboring window.
.config/kitty/whiskers_256x256.png: custom icon for kitty.

LICENSE: file containing the license information.

nvim/: configuration files for neovim, a text editor.

.config/nvim/init.lua: main configuration file for neovim.
.config/nvim/language-configs/c/c/c.clang-format: configuration file for clang-format.
.config/nvim/language-configs/java/cmsc-132-style.xml: configuration file for checkstyle.
.config/nvim/language-configs/java/custom-google-style.xml: configuration file for google-java-format.
.config/nvim/lua/.luarc.json: configuration file for lua.
.config/nvim/lua/user/: directory containing various Lua scripts for neovim.
.config/nvim/plugin/packer_compiled.lua: compiled packer configuration file.
.config/nvim/spell/: directory containing spell check files.

README.md: file containing the documentation for the dotfiles.

SETUP/: scripts to setup the dotfiles.

SETUP/setup.sh: script to setup the dotfiles.
SETUP/stow-setup.sh: script to setup stow.

shell/: configuration files for shell.

.aliases: file containing aliases for zsh.
.zshrc: configuration file for zsh.

starship.toml: configuration file for starship prompt
