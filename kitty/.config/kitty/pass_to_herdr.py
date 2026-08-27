# Hand kitty's chords to a herdr client instead of acting on kitty windows, so
# Neovim splits, herdr panes and kitty windows all answer the same keys.
#
# Kitty sees every keystroke first. When the focused window is running herdr the
# chord belongs to herdr, which either forwards it into a Neovim pane or acts on
# its own panes, and escalates back out to kitty over remote control when it
# runs out of panes in that direction. When the focused window is not running
# herdr, the kitty action given on the map line runs, unchanged.
#
#   map ctrl+h kitten pass_to_herdr.py ctrl+h neighboring_window left
#              \_______________________/ \____/ \___________________/
#                       kitten           chord   what kitty would do
#
# Same shape as the neighboring_window.py / pass_keys.py kittens next to this
# file, which do the equivalent for tmux and Neovim.
import os

from kittens.tui.handler import result_handler
from kitty.key_encoding import KeyEvent, parse_shortcut


def main():
    pass


def encode_key_mapping(window, key_mapping):
    mods, key = parse_shortcut(key_mapping)
    event = KeyEvent(
        mods=mods,
        key=key,
        shift=bool(mods & 1),
        alt=bool(mods & 2),
        ctrl=bool(mods & 4),
        super=bool(mods & 8),
        hyper=bool(mods & 16),
        meta=bool(mods & 32),
    ).as_window_system_event()

    return window.encoded_key(event)


def is_herdr(window):
    for process in window.child.foreground_processes:
        cmdline = process.get('cmdline') or []
        if cmdline and os.path.basename(cmdline[0]) == 'herdr':
            return True
    return False


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    chord, action = args[1], ' '.join(args[2:])
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    # herdr receives the exact chord the user pressed, so it can look the key up
    # in its own bindings rather than us guessing at an equivalent.
    if is_herdr(window):
        window.write_to_child(encode_key_mapping(window, chord))
        return

    # Anything kitty can be bound to in kitty.conf is valid here — boss.combine
    # is the same entry point `kitten @ action` uses.
    boss.combine(action, window)
