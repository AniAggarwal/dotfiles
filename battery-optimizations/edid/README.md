# OLED EDID with a longer vertical blank (PSR experiment)

The XPS 15 9520's 3.5K OLED (eDP-1) reports a PSR setup time of 330 µs, but its only mode
(3456x2160, 528.19 MHz, htotal 4016, vtotal 2192) has a 32-line vertical blank: about 243 µs.
On Alder Lake (display version 13) i915 then refuses PSR outright:
`PSR condition failed: PSR setup time (330 us) too long` (intel_psr_entry_setup_frames(); only
display version 20+ can spread the setup over extra frames). Without PSR the display engine
reads memory every frame, the package never gets below PC3, and about 2.5–3 W is lost.

`xps15-9520-oled-vblank48.bin` is the panel's own EDID with the vertical blank in both
detailed timings raised from 32 to 48 lines (back porch 16 → 32; same pixel clock, sync and
front porch): vtotal 2208, 59.57 Hz, vblank about 365 µs, which fits the 44 lines the setup
time needs. Nothing else changed; base-block checksum recomputed. The EDID carries no serial
number (bytes 12–15 are zero).

Whether the panel accepts the longer back porch is what the test finds out.

## Test for one boot (nothing persistent at boot)

1. Put the file where the kernel can load it, inside the initramfs (i915 loads from there):
   ```
   sudo install -Dm644 ~/dotfiles/battery-optimizations/edid/xps15-9520-oled-vblank48.bin /usr/lib/firmware/edid/xps15-9520-oled-vblank48.bin
   echo 'FILES+=(/usr/lib/firmware/edid/xps15-9520-oled-vblank48.bin)' | sudo tee /etc/mkinitcpio.conf.d/edid.conf
   sudo mkinitcpio -P
   ```
   The file is unused unless the kernel parameter below asks for it.
2. Reboot. At the GRUB menu press `e` on the normal entry, append to the `linux` line:
   ```
   drm.edid_firmware=eDP-1:edid/xps15-9520-oled-vblank48.bin
   ```
   and boot with Ctrl+X. If the laptop panel stays black or garbled, just reboot: the parameter
   is gone after one boot.
3. Check:
   ```
   hyprctl monitors | grep -A1 eDP-1                       # about 59.57 Hz
   D=/sys/kernel/debug/dri/0000:00:02.0
   sudo cat $D/i915_edp_psr_status | head -3               # PSR1 enabled, or still disabled by the VBT
   echo 0x3 | sudo tee $D/i915_edp_psr_debug               # if disabled: force PSR1
   sudo cat $D/i915_edp_psr_status | head -3
   ```
   Use it normally for a while (scrolling, typing, video, cursor) and watch for flicker, lag or
   frozen frames. Then measure idle package C-states for 60 s:
   ```
   sudo cat /sys/kernel/debug/pmc_core/package_cstate_show; sleep 60; sudo cat /sys/kernel/debug/pmc_core/package_cstate_show
   ```

## Making it permanent (only after a clean test)

Add `drm.edid_firmware=eDP-1:edid/xps15-9520-oled-vblank48.bin i915.enable_psr=1` through a
`/etc/default/grub.d/` drop-in and run `sudo grub-mkconfig -o /boot/grub/grub.cfg`.

## Undo

```
sudo rm /etc/mkinitcpio.conf.d/edid.conf /usr/lib/firmware/edid/xps15-9520-oled-vblank48.bin
sudo mkinitcpio -P
```
