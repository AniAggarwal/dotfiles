Dell XPS 15 9520 Wi-Fi 6E workaround

Verified with BIOS 1.35.0, Intel AX211 and Arch Linux. The separate test
boot loaded this SSDT and changed 6 GHz channels from 0/59 to 59/59 not
disabled. Normal default boot was also verified on 2026-10-11: Linux reported an
ACPI Table Upgrade for this SSDT and all 59 channels remained unlocked.
Ordinary 5 GHz Wi-Fi works. A real 6 GHz association has not yet
been tested; the current home router supports only 2.4/5 GHz.

Persistent files on the installed machine:
  /boot/wifi6e.cpio
  /etc/default/grub.d/90-wifi6e.cfg

The archive contains kernel/firmware/acpi/SSDT-WIFI6E.aml. Linux executes
the added CNVW._INI method to clear the OEM UHBS restriction. GRUB adds
the uncompressed archive after stock microcode and before the compressed
initramfs for normal Linux entries. Windows does not receive this archive.

Why updates retain it:
- mkinitcpio regenerates its own initramfs images; wifi6e.cpio is a separate
  persistent file and is not rebuilt or overwritten by mkinitcpio.
- grub-mkconfig sources /etc/default/grub.d/*.cfg. The drop-in uses the
  native GRUB_EARLY_INITRD_LINUX_CUSTOM option, so regeneration includes
  the archive again. The installed grub-hook package already regenerates
  GRUB after kernel installation, upgrade and removal; no extra hook is
  needed. Keep grub-hook installed for automatic kernel-update handling.
- No package owns the custom drop-in, so ordinary package updates do not
  replace it. Secure Boot must permit ACPI overrides; this host has it off.

Saved scripts:
  sudo bash /home/ani/dotfiles/wifi-6e/make-wifi6e-default.sh
  sudo bash /home/ani/dotfiles/wifi-6e/rollback-wifi6e-default.sh

The installation script is the applied migration from the separate test
entry. It reads its assets from its own directory, so it is independent
of the original Codex workspace. On this already-configured host it only
checks the installed archive and generated Linux entries, then exits.
It preserves existing kernel arguments, initrds, saved default and menu
entries, removes only the original Wi-Fi test entry and restores timeout 1.
It backs up the prior configuration in /boot/grub/wifi6e-before-default.
It intentionally checks this model/BIOS and the expected prior test files.
It is not a generic installer for a different laptop or a fresh OS image.

Rollback restores the pre-migration separate test configuration. It stops
if later updates changed grub.cfg, rather than restoring an old kernel
configuration. After updates, disabling the default override instead is:
  sudo mv /etc/default/grub.d/90-wifi6e.cfg /etc/default/grub.d/90-wifi6e.cfg.disabled
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  # After successful regeneration, the unused /boot/wifi6e.cpio can be removed.

After the next normal boot, verify:
  journalctl -k -b | rg 'LOCAL  WIFI6E|Table Upgrade|Table Override'
  iw phy phy0 info
  sudo cat /sys/kernel/debug/iwlwifi/0000:00:14.3/iwlmvm/wifi_6e_enable
Expect the SSDT loaded, six-GHz channels not disabled, and BIOS flag 0x0.
A working connection still requires an AP on 5955-7115 MHz, confirmed by:
  iw dev wlan0 link

BIOS/security-policy updates may require rechecking the ACPI objects.
The source is SSDT-WIFI6E.dsl. The compiled AML and archive are included
to preserve the exact, tested payload; changing the source requires
explicitly recompiling and rebuilding the archive before installation.
