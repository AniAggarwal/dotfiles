"""Verify that grouping changes only the location of firmware entries."""
import pathlib
import re
import sys


def section(text, name):
    result = re.search(
        rf"### BEGIN /etc/grub.d/{re.escape(name)} ###\n(.*?)### END /etc/grub.d/{re.escape(name)} ###",
        text,
        re.S,
    )
    if result is None:
        raise ValueError(f"Missing generator section: {name}")
    return result[1].strip()


def check(old, new):
    original = section(old, "31_efi_bootnext")
    if not original or section(new, "31_efi_bootnext"):
        raise ValueError("Original BootNext output must move out of the top level")
    grouped = section(new, "32_firmware_submenu")
    prefix = "submenu 'Firmware Boot Options' --id firmware-boot-options {\n"
    if not grouped.startswith(prefix) or not grouped.endswith("\n}"):
        raise ValueError("Missing expected submenu wrapper")
    if grouped[len(prefix):-2].strip() != original:
        raise ValueError("Firmware entries changed beyond grouping")
    for name in ["10_linux", "30_os-prober", "30_uefi-firmware"]:
        before, after = section(old, name), section(new, name)
        if name == "30_os-prober":
            # NVMe enumeration changes the display label, not UUID boot targets.
            label_device = r"(?m)^(\s*menuentry '[^\n]*?)\(on /dev/[^)]+\)"
            before = re.sub(label_device, r"\1(on DEVICE)", before)
            after = re.sub(label_device, r"\1(on DEVICE)", after)
        if before != after:
            raise ValueError(f"Existing boot entries changed: {name}")
    return len(re.findall(r"^\s*menuentry ", original, re.M))


if __name__ == "__main__":
    old, new = (pathlib.Path(p).read_text() for p in sys.argv[1:])
    print(f"Validated: {check(old, new)} firmware entries grouped; Linux, Windows and UEFI entries unchanged")
