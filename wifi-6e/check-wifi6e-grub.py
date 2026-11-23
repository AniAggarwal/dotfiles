"""Check generated Linux entries preserve their kernels and initrds."""
import pathlib
import shlex
import sys


def linux_boots(text):
    boots = []
    current = None
    for line in text.splitlines():
        tokens = shlex.split(line, comments=True)
        if not tokens:
            continue
        if tokens[0] == "linux":
            current = tokens
        elif tokens[0] == "initrd" and current is not None:
            boots.append((current, tokens[1:]))
            current = None
    return boots


def check(old, new):
    before, after = linux_boots(old), linux_boots(new)
    if not before or len(before) != len(after):
        raise ValueError("Linux entry count changed")
    for (kernel_old, rd_old), (kernel_new, rd_new) in zip(before, after):
        if kernel_old != kernel_new:
            raise ValueError("A kernel or its command line changed")
        if rd_new.count("/boot/wifi6e.cpio") != 1:
            raise ValueError("Each Linux entry must load the override exactly once")
        if rd_old.count("/boot/wifi6e.cpio") > 1:
            raise ValueError("Existing entry loads duplicate overrides")
        if [p for p in rd_new if p != "/boot/wifi6e.cpio"] != [p for p in rd_old if p != "/boot/wifi6e.cpio"]:
            raise ValueError("Existing initrds or their order changed")
        if rd_new[-1] == "/boot/wifi6e.cpio":
            raise ValueError("Override must precede the main initramfs")
    return len(after)


if __name__ == "__main__":
    old, new = (pathlib.Path(p).read_text() for p in sys.argv[1:])
    print(f"Validated {check(old, new)} Linux entries; existing boot arguments and initrds preserved")
