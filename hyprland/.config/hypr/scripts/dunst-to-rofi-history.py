#!/usr/bin/env python3
"""Browse dunst notification history in rofi, with icons.

Architecture:
  - Top-level invocation execs rofi in "script mode" with this file as the
    script. Rofi stays open across Alt+D deletes, so the user can hold Alt
    and press D repeatedly without rofi tearing down and re-grabbing the
    keyboard each time.
  - When invoked by rofi (ROFI_RETV in env), this file emits rows / handles
    callbacks for Enter, Alt+D, etc.
  - On Enter, a detached subprocess shows the per-notification action menu
    so rofi can close cleanly first.

Bound to CTRL+ALT+N in hyprland.conf.
"""
import subprocess
import json
import html
import os
import sys
import time
import datetime

THEME_FILE = "~/.config/rofi/notification-history.rasi"
ERROR_THEME_FILE = "~/.config/rofi/rofi-config.rasi"

# Row separator used between notification entries. Setting -delim lets rows
# contain '\n' (rendered by pango as a line break).
ROW_SEP = "\x1e"

MESG = (
    "<span size='small' alpha='70%'>"
    "<b>Enter</b>: actions  |  <b>Alt+D</b>: delete  |  <b>Esc</b>: cancel"
    "</span>"
)


# ---------- shared helpers --------------------------------------------------

def run_command(command, *, check=True):
    return subprocess.run(
        command, capture_output=True, text=True, check=check, shell=False
    )


def rofi_error(message):
    theme_path = os.path.expanduser(ERROR_THEME_FILE)
    subprocess.run(["rofi", "-e", message, "-theme", theme_path], shell=False)


def field(notif, key, default=""):
    """Dunst wraps values as {'type': ..., 'data': ...}."""
    val = notif.get(key, {})
    if isinstance(val, dict):
        return val.get("data", default)
    return val if val is not None else default


def get_ignored_appnames():
    ignored = set()
    try:
        out = run_command(["dunstctl", "rules", "--json"]).stdout
        rules_data = json.loads(out)
        for rule in rules_data.get("rules", []):
            if rule.get("history_ignore") or rule.get("skip_display"):
                appname = rule.get("appname")
                if appname:
                    ignored.add(appname)
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        pass
    return ignored


def fetch_history(ignored):
    try:
        out = run_command(["dunstctl", "history", "-f", "json"]).stdout
        history_data = json.loads(out)
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return []
    notifications = history_data.get("data", [[]])
    notifications = notifications[0] if notifications else []
    notifications = [n for n in notifications if field(n, "appname") not in ignored]
    # Sort newest first by timestamp (CLOCK_BOOTTIME µs).
    notifications.sort(key=lambda n: int(field(n, "timestamp", 0) or 0), reverse=True)
    return notifications


# ---------- timestamp formatting -------------------------------------------

# Dunst timestamps are CLOCK_BOOTTIME microseconds (includes suspend).
_BOOT_TO_WALL = time.time() - time.clock_gettime(time.CLOCK_BOOTTIME)


def ts_to_wallclock(ts_microseconds):
    try:
        return int(ts_microseconds) / 1_000_000 + _BOOT_TO_WALL
    except (ValueError, TypeError):
        return 0.0


def format_time(wall_ts):
    if not wall_ts:
        return ""
    dt = datetime.datetime.fromtimestamp(wall_ts)
    now = datetime.datetime.now()
    if dt.date() == now.date():
        return dt.strftime("Today %H:%M")
    if (now.date() - dt.date()).days == 1:
        return dt.strftime("Yesterday %H:%M")
    if dt.year == now.year:
        return dt.strftime("%b %-d  %H:%M")
    return dt.strftime("%Y-%m-%d %H:%M")


def relative_age(wall_ts):
    if not wall_ts:
        return ""
    delta = time.time() - wall_ts
    if delta < 60:
        return f"{int(delta)}s ago"
    if delta < 3600:
        return f"{int(delta / 60)}m ago"
    if delta < 86400:
        return f"{int(delta / 3600)}h ago"
    return f"{int(delta / 86400)}d ago"


# ---------- row rendering --------------------------------------------------

def build_row(notif):
    appname = field(notif, "appname", "N/A") or "N/A"
    summary = html.escape(field(notif, "summary", ""))
    body = html.escape(field(notif, "body", ""))
    body = body.replace("\n", " ").replace("\r", " ")
    wall_ts = ts_to_wallclock(field(notif, "timestamp", 0))
    when = format_time(wall_ts)
    age = relative_age(wall_ts)
    icon_path = field(notif, "icon_path", "") or ""
    nid = field(notif, "id", 0)

    header = f"<b>{summary or '(no summary)'}</b>"
    time_str = f"{when} · {age}" if when and age else when or age

    if body:
        line = (
            f"{header}  <small>· {time_str}</small>\n"
            f"<small>{html.escape(appname)}:</small> {body}"
        )
    else:
        meta_pieces = [html.escape(appname)]
        if time_str:
            meta_pieces.append(time_str)
        line = f"{header}\n<i><small>" + " · ".join(meta_pieces) + "</small></i>"

    # Per-row rofi metadata: \0icon\x1f<path>\x1finfo\x1f<id>
    meta_fields = []
    if icon_path and os.path.exists(os.path.expanduser(icon_path)):
        meta_fields.append(f"icon\x1f{icon_path}")
    if nid:
        meta_fields.append(f"info\x1f{nid}")
    if meta_fields:
        line = f"{line}\0" + "\x1f".join(meta_fields)
    return line


# ---------- script-mode entry points ---------------------------------------

def emit_listing(initial):
    """Write rofi script-mode output. On the initial call we send the
    one-shot options (delim, markup-rows, use-hot-keys, prompt). On
    refresh callbacks we only need to set keep-selection + rows."""
    out = sys.stdout
    if initial:
        # These all use the default '\n' delimiter because we haven't
        # changed it yet. The 'delim' option flips the delimiter to
        # ROW_SEP for everything that follows.
        out.write(f"\0prompt\x1fNotifications\n")
        out.write(f"\0markup-rows\x1ftrue\n")
        out.write(f"\0use-hot-keys\x1ftrue\n")
        out.write(f"\0message\x1f{MESG}\n")
        out.write(f"\0delim\x1f{ROW_SEP}\n")
    else:
        # Delim is already ROW_SEP for this run; emit control lines using it.
        out.write(f"\0keep-selection\x1ftrue{ROW_SEP}")
        out.write(f"\0message\x1f{MESG}{ROW_SEP}")

    ignored = get_ignored_appnames()
    notifs = fetch_history(ignored)
    if notifs:
        out.write(ROW_SEP.join(build_row(n) for n in notifs))
    out.flush()


def spawn_action_menu(notif_id):
    subprocess.Popen(
        [sys.executable, os.path.abspath(__file__), "--action-menu", str(notif_id)],
        start_new_session=True,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def run_script_mode():
    retv = int(os.environ.get("ROFI_RETV", "0"))
    info = os.environ.get("ROFI_INFO", "")

    if retv == 0:
        emit_listing(initial=True)
    elif retv == 1:  # Enter on entry
        if info:
            spawn_action_menu(info)
        # Output nothing -> rofi closes.
    elif retv == 10:  # Alt+D
        if info:
            subprocess.run(["dunstctl", "history-rm", info], check=False)
        emit_listing(initial=False)
    else:
        emit_listing(initial=False)


# ---------- action menu (separate process) ---------------------------------

def run_action_menu(notif_id):
    # Let the originating rofi window close first so we don't briefly stack.
    time.sleep(0.08)

    actions = ["  Copy body", "  Pop (re-show)", "  Dismiss from history"]
    theme = os.path.expanduser(ERROR_THEME_FILE)
    result = subprocess.run(
        ["rofi", "-dmenu", "-p", "Action", "-i", "-theme", theme],
        input="\n".join(actions),
        capture_output=True,
        text=True,
    )
    chosen = result.stdout.rstrip()  # preserve leading spaces
    if not chosen:
        return

    if chosen == actions[0]:
        ignored = get_ignored_appnames()
        notifs = fetch_history(ignored)
        match = next(
            (n for n in notifs if str(field(n, "id", 0)) == str(notif_id)), None
        )
        body = field(match, "body", "") if match else ""
        subprocess.run(["wl-copy"], input=body, text=True)
    elif chosen == actions[1]:
        subprocess.run(["dunstctl", "history-pop", str(notif_id)], check=False)
    elif chosen == actions[2]:
        subprocess.run(["dunstctl", "history-rm", str(notif_id)], check=False)


# ---------- top-level launcher ---------------------------------------------

def launch_rofi():
    theme = os.path.expanduser(THEME_FILE)
    script = os.path.abspath(__file__)
    os.execvp("rofi", [
        "rofi",
        "-show", "notifhist",
        "-modes", f"notifhist:{script}",
        "-theme", theme,
        "-i",
        "-show-icons",
        "-kb-custom-1", "Alt+d",
    ])


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "--action-menu":
        run_action_menu(sys.argv[2])
        return
    if "ROFI_RETV" in os.environ:
        run_script_mode()
        return
    launch_rofi()  # exec, never returns


if __name__ == "__main__":
    main()
