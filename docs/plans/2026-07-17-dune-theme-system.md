# Unified Dynamic Dune Theme System — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** One central theme under `~/dotfiles/themes` that every app draws from dynamically; picking a wallpaper regenerates (or restores from cache) the palette and live-reloads the whole desktop.

**Architecture:** matugen generates per-wallpaper color files from templates into a per-wallpaper cache dir under `~/.cache/dune-theme/`. A stable symlink `~/.config/themes/current` points at the active cache dir. Every app config *references* files inside `current` (via include/source/import mechanisms), so switching themes = flip one symlink + send reload signals. Apps that can't include external files (starship, fzf, eza, lazygit, vifm, bat) are configured to use the terminal's 16 ANSI colors, which matugen themes via kitty — so they follow the theme for free with zero per-app color config.

**Tech Stack:** matugen 4.1.0 (`scheme-content` to stay faithful to the warm wallpaper hues), bash, stow, hyprpaper, existing rofi wallpaper picker.

**Explicitly out of scope (user decision):** Neovim colorscheme (untouched), GRUB theme (untouched), hyprlock background stays `screenshot` (its *text/ring colors* do get themed). Fastfetch is handled by a separate already-dispatched agent.

---

## Layout being built

```
~/dotfiles/themes/                        # new stow package
└── .config/themes/
    └── dune/
        ├── matugen.toml                  # template registry, outputs → build dir
        └── templates/
            ├── colors-kitty.conf
            ├── colors-waybar.css
            ├── colors-rofi.rasi
            ├── colors-hyprland.conf
            ├── colors-hyprlock.conf
            ├── colors-dunst.conf
            ├── colors-btop.theme
            ├── colors-zathura
            ├── colors-swaylock
            ├── colors-gtk.css            # shared gtk3/gtk4 css
            └── colors-qt5ct.conf

~/.cache/dune-theme/
    ├── <wallpaper-stem>/                 # one cached build per wallpaper
    ├── build/                            # matugen scratch output, renamed after build
    └── last-wallpaper                    # absolute path, for boot restore

~/.config/themes/current -> ~/.cache/dune-theme/<active-stem>   # the one symlink
```

Cache key: wallpaper filename stem + mtime (`worm-into-storm-wallpaper-1699999999`), so an edited image regenerates but a mere re-pick is instant.

---

## Phase 1 — Theme core

### Task 1: Create the themes stow package + matugen config

**Files:**
- Create: `~/dotfiles/themes/.config/themes/dune/matugen.toml`
- Create: `~/dotfiles/themes/.config/themes/dune/templates/` (populated in Tasks 2–4)

**Step 1:** `mkdir -p ~/dotfiles/themes/.config/themes/dune/templates`

**Step 2:** Write `matugen.toml`. All outputs go to the scratch build dir; the apply script renames it into the cache afterward:

```toml
[config]

[templates.kitty]
input_path = "~/.config/themes/dune/templates/colors-kitty.conf"
output_path = "~/.cache/dune-theme/build/colors-kitty.conf"

[templates.waybar]
input_path = "~/.config/themes/dune/templates/colors-waybar.css"
output_path = "~/.cache/dune-theme/build/colors-waybar.css"

[templates.rofi]
input_path = "~/.config/themes/dune/templates/colors-rofi.rasi"
output_path = "~/.cache/dune-theme/build/colors-rofi.rasi"

[templates.hyprland]
input_path = "~/.config/themes/dune/templates/colors-hyprland.conf"
output_path = "~/.cache/dune-theme/build/colors-hyprland.conf"

[templates.hyprlock]
input_path = "~/.config/themes/dune/templates/colors-hyprlock.conf"
output_path = "~/.cache/dune-theme/build/colors-hyprlock.conf"

[templates.dunst]
input_path = "~/.config/themes/dune/templates/colors-dunst.conf"
output_path = "~/.cache/dune-theme/build/colors-dunst.conf"

[templates.btop]
input_path = "~/.config/themes/dune/templates/colors-btop.theme"
output_path = "~/.cache/dune-theme/build/colors-btop.theme"

[templates.zathura]
input_path = "~/.config/themes/dune/templates/colors-zathura"
output_path = "~/.cache/dune-theme/build/colors-zathura"

[templates.swaylock]
input_path = "~/.config/themes/dune/templates/colors-swaylock"
output_path = "~/.cache/dune-theme/build/colors-swaylock"

[templates.gtk]
input_path = "~/.config/themes/dune/templates/colors-gtk.css"
output_path = "~/.cache/dune-theme/build/colors-gtk.css"

[templates.qt5ct]
input_path = "~/.config/themes/dune/templates/colors-qt5ct.conf"
output_path = "~/.cache/dune-theme/build/colors-qt5ct.conf"
```

**Step 3:** `stow -d ~/dotfiles themes` — verify `~/.config/themes/dune/matugen.toml` resolves.

**Step 4:** Commit: `feat(themes): add central dune theme package with matugen registry`

### Task 2: Terminal + bar + launcher templates (kitty, waybar, rofi)

matugen template syntax: `{{colors.<role>.default.hex}}` (and `.hex_stripped` for no-`#` formats). Roles used: `primary` (spice), `secondary`, `tertiary` (reserve for Fremen-blue-ish accent), `surface`, `surface_container`, `on_surface`, `error`, plus `{{colors.source_color.default.hex}}`.

**Step 1:** `colors-kitty.conf` — full 16-color ANSI table + fg/bg/cursor/selection/tab colors mapped from matugen roles. This is the linchpin: every ANSI-consuming TUI inherits from it. Map: background→surface, foreground→on_surface, color3/11 (yellow)→primary, color1/9 (red)→error, color4/12 (blue)→tertiary, etc.

**Step 2:** `colors-waybar.css` — only `@define-color` lines (panel_bg, bar_fg, accent_workspace_active, accent_charging, accent_critical, …) matching the variable names already used in `~/dotfiles/waybar/.config/waybar/style.css`.

**Step 3:** `colors-rofi.rasi` — same variable names as the existing `~/.config/rofi/colors/dune.rasi` so every rasi theme that imports it keeps working.

**Step 4:** Smoke test: `matugen image ~/data/photos/dune-wallpapers/worm-into-storm-wallpaper.jpg -c ~/.config/themes/dune/matugen.toml -t scheme-content` (expected: files appear in `~/.cache/dune-theme/build/`; ignore missing-template errors for templates not written yet). Inspect hexes are warm/sandy.

**Step 5:** Commit: `feat(themes): kitty/waybar/rofi matugen templates`

### Task 3: Hyprland, hyprlock, dunst, swaylock templates

**Step 1:** `colors-hyprland.conf` — hyprland `$variables` only (e.g. `$activeBorder1 = rgb({{colors.primary.default.hex_stripped}})`, `$inactiveBorder`, `$shadow`).

**Step 2:** `colors-hyprlock.conf` — hyprlock `$variables` for font/ring/inner colors only. Background stays `screenshot` (do not template `path`).

**Step 3:** `colors-dunst.conf` — a full dunst drop-in with `[urgency_low]`, `[urgency_normal]`, `[urgency_critical]` sections (dunst drop-ins can't be just color vars; sections are self-contained). critical uses error role.

**Step 4:** `colors-swaylock` — `key=value` lines in swaylock config syntax (`inside-color=…`, `ring-color=…`) to be included via the lock script.

**Step 5:** Rerun matugen smoke test; commit: `feat(themes): hyprland/hyprlock/dunst/swaylock templates`

### Task 4: btop, zathura, GTK, Qt templates

**Step 1:** `colors-btop.theme` — full btop theme (`theme[main_bg]`, `theme[main_fg]`, gradients from surface→primary).

**Step 2:** `colors-zathura` — `set recolor-darkcolor`, `set recolor-lightcolor`, `set default-bg`, statusbar/inputbar colors as zathurarc syntax.

**Step 3:** `colors-gtk.css` — `@define-color accent_color …; @define-color accent_bg_color …; @define-color window_bg_color …;` etc. (libadwaita named colors; also works for GTK3 apps reading gtk.css).

**Step 4:** `colors-qt5ct.conf` — a qt5ct color scheme file (`[ColorScheme]\nactive_colors=…` 21-color list) built from the same roles.

**Step 5:** Rerun matugen; now zero template errors. Commit: `feat(themes): btop/zathura/gtk/qt templates`

---

## Phase 2 — Apply script + wallpaper picker integration

### Task 5: `theme-apply.sh`

**Files:**
- Create: `~/dotfiles/hyprland/.config/hypr/scripts/theme-apply.sh` (lands in `~/.config/hypr/scripts/` via existing stow)

**Behavior:**

```bash
#!/bin/bash
# theme-apply.sh <wallpaper-path>
set -euo pipefail
wp="$1"; [ -f "$wp" ] || exit 1
cache_root="$HOME/.cache/dune-theme"
stem="$(basename "${wp%.*}")-$(stat -c %Y "$wp")"
target="$cache_root/$stem"

if [ ! -d "$target" ]; then
    rm -rf "$cache_root/build"; mkdir -p "$cache_root/build"
    matugen image "$wp" -c "$HOME/.config/themes/dune/matugen.toml" -t scheme-content
    mv "$cache_root/build" "$target"
fi

ln -sfn "$target" "$HOME/.config/themes/current"
echo "$wp" > "$cache_root/last-wallpaper"

# live reloads (each best-effort)
pkill -SIGUSR1 kitty || true            # kitty reloads config in place
pkill -SIGUSR2 waybar || true           # waybar re-reads style.css
dunstctl reload || true
hyprctl reload || true
# GTK live nudge: flip color-scheme twice so running apps re-read named colors
gsettings set org.gnome.desktop.interface color-scheme 'default' && \
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
notify-send "Dune theme" "Applied palette from $(basename "$wp")" || true
```

**Steps:** write it → `chmod +x` → run once manually against `worm-into-storm-wallpaper.jpg` → verify `~/.config/themes/current` symlink exists and points into cache → run again and verify it's instant (cache hit, no matugen call — check with `time`) → commit `feat(themes): theme-apply script with per-wallpaper cache`.

### Task 6: Hook the picker + boot restore

**Files:**
- Modify: `~/dotfiles/hyprland/.config/hypr/scripts/wallpaper-picker.sh` (append after the `hyprctl hyprpaper wallpaper` lines)
- Modify: `~/dotfiles/hyprland/.config/hypr/hyprland.lua` (exec-once)

**Step 1:** In `wallpaper-picker.sh`, after setting the wallpaper add:
```bash
"$HOME/.config/hypr/scripts/theme-apply.sh" "$wallpaper" &
```

**Step 2:** Boot restore — hyprpaper can't include files, so add an exec-once (or extend an existing startup script) that reads `~/.cache/dune-theme/last-wallpaper`, preloads/sets it via `hyprctl hyprpaper`, and runs `theme-apply.sh` on it. Falls back to current hyprpaper.conf default when the file is absent.

**Step 3:** Test via the pypr shortcuts menu ("Choose Wallpaper") end-to-end: pick each of the 6 wallpapers once (populates cache), pick again (instant). Commit: `feat(themes): wallpaper picker drives theme + boot restore`

---

## Phase 3 — Wire every consumer to `current`

Each task: edit config to reference `~/.config/themes/current/<file>`, delete/retire the now-dead hardcoded colors, reload, eyeball, commit. One commit per app.

### Task 7: kitty
`~/dotfiles/kitty/.config/kitty/kitty.conf`: replace `include onedark-theme.conf` with `include ~/.config/themes/current/colors-kitty.conf`. Keep `onedark-theme.conf` in the repo but unreferenced (cheap rollback). Verify with `kitty +kitten icat` open new terminal.

### Task 8: waybar
`style.css`: replace the hardcoded `@define-color` block with `@import "../themes/current/colors-waybar.css";` (waybar CSS supports @import with relative paths from the config dir; use absolute `file://` path if relative fails). Kill Tokyo Night hexes (`#1a1b26`, `#7dcfff`, `#ec7189`, `#ffffff`).

### Task 9: rofi
Make `~/.config/rofi/colors/dune.rasi` a thin wrapper: `@import "~/.config/themes/current/colors-rofi.rasi"` — every existing rasi that imports `dune.rasi` follows automatically. Then audit `rofi-config.rasi`, `clipboard.rasi`, `notification-history.rasi`, `wallpaper-picker.rasi` for hardcoded hexes and swap them to the shared vars.

### Task 10: dunst
Dunst reads `~/.config/dunst/dunstrc.d/*.conf` drop-ins. Create symlink `~/dotfiles/dunst/.config/dunst/dunstrc.d/99-colors.conf -> ~/.config/themes/current/colors-dunst.conf` (stow carries symlinks). Remove color keys from main dunstrc; also switch `font` to the Nerd Font used elsewhere. `dunstctl reload` + `notify-send -u critical test`.

### Task 11: hyprland + hyprlock + swaylock
- `hyprland.lua`: source/read `~/.config/themes/current/colors-hyprland.conf` for border/shadow vars (the lua config can read the file; if awkward, generate a `.conf` sourced via hyprland's `source =` alongside the lua). Re-enable blur + shadow with themed shadow color.
- `hyprlock.conf`: add `source = ~/.config/themes/current/colors-hyprlock.conf`, swap hardcoded grays to the `$vars`. Background stays `screenshot`. Fix the missing-font reference while here.
- `lock-screen.sh`: build swaylock args from `~/.config/themes/current/colors-swaylock` (e.g. `swaylock $(sed 's/^/--/' … | tr '\n' ' ')`) replacing hardcoded `696969`/`AEAEAE`.

### Task 12: btop + zathura
- `btop.conf`: `color_theme = "~/.config/themes/current/colors-btop.theme"` (btop accepts absolute paths).
- `zathurarc`: `include ~/.config/themes/current/colors-zathura`.

### Task 13: ANSI-follower apps (no generated files needed)
- **bat** (`~/.config/bat/config`): `--theme="ansi"` — tracks terminal palette.
- **fzf** (`~/.zshrc` `fzf_config()`): `FZF_DEFAULT_OPTS` using ANSI indices (`--color=16,bg+:0,fg+:11,hl:3,pointer:9,…`), no hexes.
- **lazygit** (`~/.config/lazygit/config.yml`): theme block using ANSI names (`activeBorderColor: [yellow, bold]`, etc.).
- **vifm**: colorscheme file using cterm 0–15 colors.
- **starship** (`starship.toml`): add `[palettes.dune]` mapping to ANSI names + Dune-flavored prompt glyphs; module styles reference palette names.
- **eza**: `EZA_COLORS` with ANSI indices in `~/.zshrc`.
One commit: `feat(themes): route TUI apps through terminal ANSI palette`.

### Task 14: GTK
- Create `~/dotfiles/themes/.config/gtk-4.0/gtk.css` and `.config/gtk-3.0/gtk.css` each containing only `@import url("file:///home/ani/.config/themes/current/colors-gtk.css");` (real files in the themes stow package; note gtk-4.0 dir currently unmanaged — adopt into stow, resolving conflicts explicitly).
- Add `~/.config/gtk-3.0/settings.ini` (currently missing) with theme/font/icon settings.
- Verify with a libadwaita app (deja-dup/nautilus-style) and a GTK3 app (GIMP dialogs).

### Task 15: Qt
- `~/.config/qt5ct/qt5ct.conf`: set `color_scheme_path=/home/ani/.config/themes/current/colors-qt5ct.conf`, `custom_palette=true`; keep Fusion-style widget style (swap `style=Windows` → `Fusion`). Qt apps pick the palette up on restart (documented limitation — no live reload).
- Verify with qBittorrent/KeePassXC after Task 16.

### Task 16: One-time app cleanups
- qBittorrent: remove `CustomUIThemePath=…dracula.qbtheme` from `~/.config/qBittorrent/qBittorrent.conf` (falls back to Qt palette from Task 15).
- Brave: **DONE (2026-07-22).** Closed Brave, edited `~/.config/BraveSoftware/Brave-Browser/Default/Preferences` → `browser.theme.is_grayscale=false` (+`is_grayscale2`) and `user_color=-3629205` (+`user_color2`) = spice amber `#C89F6B` (`0xFFC89F6B` as signed SkColor). Fixed accent, not wallpaper-dynamic (Brave rewrites Preferences on exit + is in constant use). Backup at `Preferences.bak.dune`. Verified persisted across a clean start/stop cycle.
- VS Code `settings.json`: set an explicit warm theme (user picks; suggest "Gruvbox Material Dark").
- KeePassXC: dark theme + accent note.
One commit.

---

## Phase 4 — Polish (after core system proven)

### Task 17: Desktop-wide statics
- Icons: `pacman -S papirus-icon-theme` + `paru -S papirus-folders` → `papirus-folders -C paleorange -t Papirus-Dark`; set in gsettings + qt5ct.
- Cursor: `paru -S bibata-cursor-theme-bin` (Bibata-Modern-Amber); gsettings + Hyprland `env = XCURSOR_THEME`/`HYPRCURSOR_THEME`.

### Task 18: Dune narrative flair
- Wire `~/.config/hypr/quotes.json` into hyprlock (a `label` running a jq random-quote command) and/or a waybar tooltip module.
- Animation curves: retune `overshot`/`swipe` beziers in `hyprland.lua` for slower sand-drift motion.

### Task 19 (optional, evaluate later): swww for wallpaper crossfades (drop-in replacement for hyprpaper in picker + boot-restore script).

---

## Deferred / Future (user decisions, 2026-07-17)
- **VS Code warm theme**: skipped — user doesn't need it. Currently "Default Dark Modern".
- **Brave accent/grayscale**: **DONE (2026-07-22).** Grayscale cleared + spice-amber `user_color` (`#C89F6B` / signed SkColor `-3629205`) set directly in the profile `Preferences` while Brave was closed; verified it survives a clean start/stop. Fixed accent (not per-wallpaper) since Brave persists theme in its own profile, not a stowed file. To retint later: close Brave, change `browser.theme.user_color`/`user_color2` in `Preferences`, reopen (or use brave://settings/appearance).
- **hyprsunset ambient warmth**: declined.
- **swww**: declined — user prefers Hyprland-native tools (hyprpaper stays).
- **Papirus icon theme**: skipped — marginal benefit without a file manager.
- **kitty theming**: opted OUT via `~/.config/themes/kitty.conf` toggle symlink (points at onedark); flip to `~/.config/themes/current/colors-kitty.conf` to opt in. Terminal TUIs (bat/fzf/lazygit/vifm/starship) follow the terminal ANSI palette by design, so they stay One Dark while opted out.
- **nvim, GRUB**: permanently out of scope.

---

## Verification checklist (end state)
1. Pick "Caladan Ship" in the pypr menu → new palette everywhere within ~2s, notification fires.
2. Pick "Worm Into Storm" → instant (cached), `time theme-apply.sh` < 200ms.
3. Reboot → last wallpaper + theme restored.
4. `rg -i '1a1b26|7dcfff|ec7189|onedark|dracula' ~/dotfiles` → no live references (rollback files exempt).
5. nvim colorscheme and GRUB untouched: `git -C ~/dotfiles log --oneline -- nvim grub-theme` shows no new commits.
