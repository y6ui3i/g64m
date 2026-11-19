#!/usr/bin/env python3
"""Makes images/initramfs64-mini, a small initramfs for the 64-bit machine (E099).

    tools/images/make-mini64.py [images/initramfs64-lts]

Takes busybox and the C library it is linked with out of Alpine's x86_64 netboot initramfs
(https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/netboot/initramfs-lts) and
puts them, with an `init` that mounts /proc, /sys and /dev and starts a shell on the
console, into a new cpio archive. No kernel module is in it: this machine's first devices
are ones the kernel has built in.
"""
import gzip
import os
import stat
import sys

INIT = b"""#!/bin/sh
/bin/busybox --install -s /bin
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev
echo g86m: init
cd /root
export HOME=/root
exec setsid sh -c 'exec sh </dev/ttyS0 >/dev/ttyS0 2>&1'
"""


def read_newc(data):
    """The files of a cpio archive in the "newc" format: name -> (mode, body, target)."""
    out, at = {}, 0
    while at + 110 <= len(data):
        if data[at:at + 6] != b"070701":
            break
        f = [int(data[at + 6 + i * 8:at + 14 + i * 8], 16) for i in range(13)]
        mode, size, namesize = f[1], f[6], f[11]
        name = data[at + 110:at + 110 + namesize - 1].decode()
        at = (at + 110 + namesize + 3) & ~3
        body = data[at:at + size]
        at = (at + size + 3) & ~3
        if name == "TRAILER!!!":
            break
        out[name] = (mode, body)
    return out


def entry(name, mode, body=b"", rdev=(0, 0), ino=[1]):
    ino[0] += 1
    n = name.encode() + b"\0"
    head = b"070701" + b"".join(b"%08X" % v for v in
                                [ino[0], mode, 0, 0, 1, 0, len(body), 0, 0, rdev[0], rdev[1], len(n), 0])
    out = head + n
    out += b"\0" * (-len(out) % 4)
    out += body
    out += b"\0" * (-len(out) % 4)
    return out


def main():
    here = os.path.join(os.path.dirname(__file__), "..", "..", "images")
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "initramfs64-lts")
    files = read_newc(gzip.open(src, "rb").read())
    # Where each is in Alpine's archive (which has /bin and /lib as links into /usr).
    want = {"bin/busybox": "usr/bin/busybox", "lib/ld-musl-x86_64.so.1": "usr/lib/ld-musl-x86_64.so.1"}
    out = b""
    for d in ["bin", "lib", "dev", "proc", "sys", "tmp", "root", "etc"]:
        out += entry(d, stat.S_IFDIR | 0o755)
    for name, at in want.items():
        mode, body = files[at]
        out += entry(name, stat.S_IFREG | 0o755, body)
    out += entry("lib/libc.musl-x86_64.so.1", stat.S_IFLNK | 0o777, b"ld-musl-x86_64.so.1")
    out += entry("bin/sh", stat.S_IFLNK | 0o777, b"busybox")
    out += entry("init", stat.S_IFREG | 0o755, INIT)
    out += entry("dev/console", stat.S_IFCHR | 0o600, rdev=(5, 1))
    out += entry("dev/null", stat.S_IFCHR | 0o666, rdev=(1, 3))
    out += entry("TRAILER!!!", 0)
    dst = os.path.join(here, "initramfs64-mini")
    with open(dst, "wb") as f:
        f.write(gzip.compress(out, 9, mtime=0))
    print(f"{dst}: {os.path.getsize(dst)} bytes, busybox {len(files['usr/bin/busybox'][1])} bytes")


main()
