#!/usr/bin/env bash
set -euo pipefail

levels=(0 25 50 75 100)

get_level() {
  dunstctl get-pause-level 2>/dev/null || echo 0
}

set_level() {
  dunstctl set-pause-level "$1" >/dev/null
}

state_for() {
  case "$1" in
    0)  echo "all" ;;
    25) echo "reduced" ;;
    50) echo "quiet" ;;
    75) echo "critical" ;;
    100) echo "none" ;;
    *)  echo "all" ;;
  esac
}

print_json() {
  local lvl="$1"
  local state
  state="$(state_for "$lvl")"
  # Waybar reads: text, alt, tooltip, class
  printf '{"text":"%s","alt":"%s","tooltip":"Dunst pause level: %s","class":["lvl-%s"], "percentage":%s}\n' \
    "$state" "$state" "$lvl" "$lvl" "$lvl"
}

cycle() {
  local cur next
  cur="$(get_level)"
  for i in "${!levels[@]}"; do
    if [[ "${levels[$i]}" -eq "$cur" ]]; then
      next=$(( (i + 1) % ${#levels[@]} ))
      set_level "${levels[$next]}"
      return
    fi
  done
  set_level "${levels[0]}"
}

case "${1:---print}" in
  --cycle) cycle ;;
  --set) set_level "${2:?level required (0|25|50|75)}" ;;
  --print|*) print_json "$(get_level)";;
esac
