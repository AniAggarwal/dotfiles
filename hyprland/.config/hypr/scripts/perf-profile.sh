#!/usr/bin/env bash
# Waybar drawer for overriding the auto-cpufreq profile.
#
# auto-cpufreq stores overrides as pickles that exist only while an override is
# active (absent file == no override). They persist until explicitly cleared. Both are world-readable, so the whole UI
# reads its state without root. Every read below uses bash builtins only, so a
# module tick costs the one fork for this script and nothing further.
set -uo pipefail

GOV_STATE=/opt/auto-cpufreq/override.pickle
TURBO_STATE=/opt/auto-cpufreq/turbo-override.pickle
SIGNAL=6

# The privileged half. Not /usr/bin/auto-cpufreq: pkexec authorises a binary
# path and ignores arguments, and auto-cpufreq takes --config, whose values
# reach a shell=True run() unvalidated. Naming it directly would make the
# polkit action a root shell. This shim accepts six literal tokens and nothing
# else. Sources live in battery-optimizations/. The helper starts the daemon.
OVERRIDE_HELPER=/usr/local/bin/auto-cpufreq-override

# Glyphs (FiraCode Nerd Font, nf-md-*)
ICON_NORMAL="󰾅"        # speedometer-medium: no governor override
ICON_PERFORMANCE="󰓅"   # speedometer
ICON_POWERSAVE="󰾆"     # speedometer-slow
ICON_RESET="󰑐"         # refresh
ICON_TURBO_ALWAYS="󰉁"  # flash
ICON_TURBO_NEVER="󰉂"   # flash-off
ICON_TURBO_AUTO="󰉃"    # flash-auto

# Inactive buttons dim via pango rather than a CSS class, so highlighting does
# not depend on which widget waybar hangs `children-class` off of.
DIM_OPEN="<span alpha='45%'>"
DIM_CLOSE="</span>"

gov=reset
turbo=auto

read_state() {
  local s
  if [[ -f $GOV_STATE ]]; then
    # $(<file) reads without forking; the braces mute bash's null-byte warning,
    # which the pickle framing would otherwise emit on every tick.
    { s=$(<"$GOV_STATE"); } 2>/dev/null
    case $s in
      *performance*) gov=performance ;;
      *powersave*) gov=powersave ;;
    esac
  fi
  if [[ -f $TURBO_STATE ]]; then
    { s=$(<"$TURBO_STATE"); } 2>/dev/null
    case $s in
      *always*) turbo=always ;;
      *never*) turbo=never ;;
    esac
  fi
}

# Answers in $REPLY rather than stdout: $(sysfs ...) would fork a subshell.
sysfs() {
  REPLY=''
  if [[ -r $1 ]]; then { REPLY=$(<"$1"); } 2>/dev/null; fi
  [[ -n $REPLY ]] || REPLY='?'
}

icon_for() {
  case "$1 $2" in
    "gov performance") REPLY=$ICON_PERFORMANCE ;;
    "gov powersave") REPLY=$ICON_POWERSAVE ;;
    "gov reset") REPLY=$ICON_RESET ;;
    "turbo always") REPLY=$ICON_TURBO_ALWAYS ;;
    "turbo never") REPLY=$ICON_TURBO_NEVER ;;
    "turbo auto") REPLY=$ICON_TURBO_AUTO ;;
    *) return 1 ;;
  esac
}

tip_for() {
  case "$1 $2" in
    "gov performance") REPLY="Force performance profile" ;;
    "gov powersave") REPLY="Force powersave profile" ;;
    "gov reset") REPLY="Clear governor override" ;;
    "turbo always") REPLY="Force turbo boost on" ;;
    "turbo never") REPLY="Force turbo boost off" ;;
    "turbo auto") REPLY="Clear turbo override" ;;
    *) return 1 ;;
  esac
}

# Collapsed module: current override state, with the live values in the tooltip.
cmd_status() {
  read_state

  local icon=$ICON_NORMAL
  case $gov in
    performance) icon=$ICON_PERFORMANCE ;;
    powersave) icon=$ICON_POWERSAVE ;;
  esac

  local class=normal
  [[ $gov != reset || $turbo != auto ]] && class=override

  local now_gov now_epp now_pp turbo_now power
  sysfs /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor && now_gov=$REPLY
  sysfs /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference && now_epp=$REPLY
  sysfs /sys/firmware/acpi/platform_profile && now_pp=$REPLY
  sysfs /sys/devices/system/cpu/intel_pstate/no_turbo
  case $REPLY in 1) turbo_now=off ;; 0) turbo_now=on ;; *) turbo_now='?' ;; esac
  sysfs /sys/class/power_supply/AC/online
  case $REPLY in 1) power=AC ;; *) power=battery ;; esac

  # \\n survives into the printf output as a real \n escape for waybar's JSON.
  local tip="override: governor=$gov turbo=$turbo\\n"
  tip+="\\nnow on $power:\\n"
  tip+="  governor  $now_gov\\n"
  tip+="  epp       $now_epp\\n"
  tip+="  platform  $now_pp\\n"
  tip+="  turbo     $turbo_now"

  printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' \
    "$icon" "$gov" "$class" "$tip"
}

# Drawer button: full-opacity glyph when its value is the one in effect.
cmd_active() {
  local kind="$1" value="$2" current icon tip
  read_state
  case $kind in
    gov) current=$gov ;;
    turbo) current=$turbo ;;
    *) return 1 ;;
  esac
  icon_for "$kind" "$value" || return 1
  icon=$REPLY
  tip_for "$kind" "$value" || return 1
  tip=$REPLY

  if [[ $current == "$value" ]]; then
    printf '{"text":"%s","class":"active","tooltip":"%s"}\n' "$icon" "$tip"
  else
    printf '{"text":"%s%s%s","class":"inactive","tooltip":"%s"}\n' \
      "$DIM_OPEN" "$icon" "$DIM_CLOSE" "$tip"
  fi
}

# Apply an override. Only this call is privileged; polkit prompts for a finger.
cmd_set() {
  local token="$1-$2" rc=0
  # Same six tokens the shim accepts, checked here too so a typo in
  # config.jsonc fails visibly instead of as a bare exit 64 from root.
  case $token in
    force-performance | force-powersave | force-reset) ;;
    turbo-always | turbo-never | turbo-auto) ;;
    *)
      echo "unknown override: $token" >&2
      return 1
      ;;
  esac

  pkexec "$OVERRIDE_HELPER" "$token" >/dev/null 2>&1 || rc=$?
  # 126 is "dismissed or failed authentication" — polkit already said so.
  if ((rc != 0 && rc != 126)); then
    notify-send -u critical "auto-cpufreq" "Failed to apply $token (exit $rc)" 2>/dev/null
  fi
  # The pickle is written synchronously by the CLI, so state is already correct.
  pkill "-SIGRTMIN+$SIGNAL" waybar || true
  return "$rc"
}

case "${1:-status}" in
  status) cmd_status ;;
  active) cmd_active "${2:?gov|turbo required}" "${3:?value required}" ;;
  set) cmd_set "${2:?force|turbo required}" "${3:?value required}" ;;
  *)
    echo "usage: ${0##*/} status | active <gov|turbo> <value> | set <force|turbo> <value>" >&2
    exit 1
    ;;
esac
