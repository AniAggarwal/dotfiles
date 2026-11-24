#!/bin/sh
# Installs the CPU power settings as root-owned copies. Never symlinks: root must not read its
# config or run code from this user-owned repo.
#   sudo sh ~/dotfiles/battery-optimizations/install.sh            install or update
#   sudo sh ~/dotfiles/battery-optimizations/install.sh --config   also replace /etc/ani-power.conf
# /etc/ani-power.conf is copied only when missing (or with --config): after that the ani-bar
# CPU panel edits the /etc copy, and this repo's ani-power.conf is only the starting point.
# Lint: `shellcheck -s sh -o all` is clean apart from SC2250 (braces around every variable,
# style only), disabled on purpose.
# shellcheck disable=SC2250
set -eu
PATH=/usr/bin
export PATH

uid=$(id -u)
if [ "$uid" != 0 ]; then
    echo "run with sudo" >&2
    exit 1
fi
script=$(readlink -f "$0")
here=$(dirname "$script")

install -m 755 -o root -g root "$here/power-apply" /usr/local/bin/power-apply
install -m 644 -o root -g root "$here/org.ani.power-apply.policy" /usr/share/polkit-1/actions/org.ani.power-apply.policy
install -m 644 -o root -g root "$here/85-ani-power.rules" /etc/udev/rules.d/85-ani-power.rules
install -m 644 -o root -g root "$here/ani-power.service" /etc/systemd/system/ani-power.service
if [ -L /etc/ani-power.conf ]; then
    rm -f /etc/ani-power.conf
fi
if [ ! -e /etc/ani-power.conf ] || [ "${1:-}" = --config ]; then
    install -m 644 -o root -g root "$here/ani-power.conf" /etc/ani-power.conf
fi
install -d -m 755 -o root -g root /var/lib/ani-power

systemctl daemon-reload
udevadm control --reload
systemctl enable ani-power.service
systemctl start ani-power.service
