#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run this script with sudo.' >&2; exit 1; }
task_outputs=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
task_backup=/boot/grub/wifi6e-before-default
task_dropin=/etc/default/grub.d/90-wifi6e.cfg
[[ $(cat /sys/class/dmi/id/product_name) == 'XPS 15 9520' ]]
[[ $(cat /sys/class/dmi/id/bios_version) == '1.35.0' ]]
if [[ -e $task_dropin ]]; then
    cmp "$task_outputs/wifi6e-default.cfg" "$task_dropin"
    cmp "$task_outputs/wifi6e.cpio" /boot/wifi6e.cpio
    grub-script-check /boot/grub/grub.cfg
    python3 "$task_outputs/check-wifi6e-grub.py" /boot/grub/grub.cfg /boot/grub/grub.cfg
    echo 'Wi-Fi 6E default configuration is already installed and valid.'
    exit 0
fi
[[ ! -e $task_backup && ! -e $task_dropin && ! -e /boot/wifi6e.cpio ]]
# The test entry's partition UUIDs come from this boot's command line, not the repository.
root_uuid=$(sed -n 's/.*\broot=UUID=\([^ ]*\).*/\1/p' /proc/cmdline)
swap_uuid=$(sed -n 's/.*\bresume=UUID=\([^ ]*\).*/\1/p' /proc/cmdline)
[[ -n $root_uuid && -n $swap_uuid ]]
grep -v '^#@ ' "$task_outputs/wifi6e-custom.cfg.in" |
    sed -e "s/@ROOT_UUID@/$root_uuid/g" -e "s/@SWAP_UUID@/$swap_uuid/g" | cmp - /boot/grub/custom.cfg
cmp "$task_outputs/SSDT-WIFI6E.aml" /boot/SSDT-WIFI6E.aml
grub-script-check /boot/grub/grub.cfg
mkdir -m 0700 "$task_backup"
cp -a /boot/grub/grub.cfg "$task_backup/grub.cfg"
cp -a /boot/grub/custom.cfg "$task_backup/custom.cfg"
cp -a /boot/SSDT-WIFI6E.aml "$task_backup/SSDT-WIFI6E.aml"
cp -a /boot/grub/grubenv "$task_backup/grubenv"
task_complete=false
restore_on_failure() {
    if [[ $task_complete == false ]]; then
        cp -a "$task_backup/grub.cfg" /boot/grub/grub.cfg
        cp -a "$task_backup/custom.cfg" /boot/grub/custom.cfg
        cp -a "$task_backup/SSDT-WIFI6E.aml" /boot/SSDT-WIFI6E.aml
        rm -f "$task_dropin" /boot/wifi6e.cpio
        echo "Migration failed; previous boot configuration restored. Backup: $task_backup" >&2
    fi
}
trap restore_on_failure EXIT
mkdir -p /etc/default/grub.d
install -m 0644 "$task_outputs/wifi6e.cpio" /boot/wifi6e.cpio
install -m 0644 "$task_outputs/wifi6e-default.cfg" "$task_dropin"
grub-mkconfig -o "$task_backup/grub.cfg.candidate"
grub-script-check "$task_backup/grub.cfg.candidate"
python3 "$task_outputs/check-wifi6e-grub.py" "$task_backup/grub.cfg" "$task_backup/grub.cfg.candidate"
install -m 0600 "$task_backup/grub.cfg.candidate" /boot/grub/grub.cfg.wifi6e-new
mv /boot/grub/grub.cfg.wifi6e-new /boot/grub/grub.cfg
rm /boot/grub/custom.cfg /boot/SSDT-WIFI6E.aml
task_complete=true
echo 'Default Arch entries now load the override. The extra test entry is removed.'
echo 'Menu timeout is back to the configured one second; saved default is unchanged.'
echo "Previous configuration saved at $task_backup"
echo 'No reboot scheduled. After rebooting normally, verify the override again.'
