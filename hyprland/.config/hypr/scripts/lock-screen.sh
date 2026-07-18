#!/usr/bin/env bash

# Dune theme: build --color args from the matugen-generated swaylock palette
# (~/.config/themes/current/colors-swaylock). Each line is a dash-less
# key=value (or bare flag), so prefix with -- to turn it into a swaylock arg.
colors="$HOME/.config/themes/current/colors-swaylock"
theme_args=()
if [[ -r "$colors" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        theme_args+=("--$line")
    done <"$colors"
fi

swaylock -f --config ~/.config/swaylock-effects/config "${theme_args[@]}"
