#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run this script with sudo.' >&2; exit 1; }
task_outputs=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
task_backup=/boot/grub/wifi6e-before-default
cmp "$task_outputs/wifi6e-default.cfg" /etc/default/grub.d/90-wifi6e.cfg
cmp "$task_outputs/wifi6e.cpio" /boot/wifi6e.cpio
cmp "$task_backup/grub.cfg.candidate" /boot/grub/grub.cfg
[[ ! -e /boot/grub/custom.cfg && ! -e /boot/SSDT-WIFI6E.aml ]]
grub-script-check "$task_backup/grub.cfg"
cp -a "$task_backup/custom.cfg" /boot/grub/custom.cfg
cp -a "$task_backup/SSDT-WIFI6E.aml" /boot/SSDT-WIFI6E.aml
cp -a "$task_backup/grub.cfg" /boot/grub/grub.cfg
rm /etc/default/grub.d/90-wifi6e.cfg /boot/wifi6e.cpio
echo 'Restored the previous configuration: normal boot has no override; the separate test entry is available.'
