#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run this script with sudo.' >&2; exit 1; }
task_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
task_backup=/boot/grub/before-firmware-submenu
task_dropin=/etc/default/grub.d/91_firmware_submenu.cfg
task_generator=/etc/grub.d/32_firmware_submenu
[[ ! -e $task_dropin && ! -e $task_generator ]]
test -x /etc/grub.d/31_efi_bootnext
rg -q '^  GRUB_DISABLE_BOOTNEXT ' /usr/sbin/grub-mkconfig
grub-script-check /boot/grub/grub.cfg
if [[ -e $task_backup ]]; then
    cmp "$task_backup/grub.cfg" /boot/grub/grub.cfg
else
    mkdir -m 0700 "$task_backup"
    cp -a /boot/grub/grub.cfg "$task_backup/grub.cfg"
fi
task_complete=false
restore_on_failure() {
    if [[ $task_complete == false ]]; then
        cp -a "$task_backup/grub.cfg" /boot/grub/grub.cfg
        rm -f "$task_dropin" "$task_generator"
        echo 'Grouping failed; previous configuration restored.' >&2
    fi
}
trap restore_on_failure EXIT
mkdir -p /etc/default/grub.d
install -m 0644 "$task_dir/91_firmware_submenu.cfg" "$task_dropin"
install -m 0755 "$task_dir/32_firmware_submenu" "$task_generator"
grub-mkconfig -o "$task_backup/grub.cfg.candidate"
grub-script-check "$task_backup/grub.cfg.candidate"
python3 "$task_dir/check-menu.py" "$task_backup/grub.cfg" "$task_backup/grub.cfg.candidate"
install -m 0600 "$task_backup/grub.cfg.candidate" /boot/grub/grub.cfg.submenu-new
mv /boot/grub/grub.cfg.submenu-new /boot/grub/grub.cfg
task_complete=true
if [[ $# == 1 ]]; then
    install -m 0644 /boot/grub/grub.cfg "$1"
fi
echo 'Installed Firmware Boot Options submenu. Saved default and timeout unchanged.'
echo "Previous configuration: $task_backup"
echo 'No reboot scheduled.'
