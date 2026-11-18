#!/bin/sh
# Makes images/disk-x.img for M8 (docs/roadmap.md): an ext2 file system with X on it, to be
# the root on the IDE disk.
#
#   XROOT=/path/to/rustx86/images/disk-x.img tools/images/make-x-disk.sh
#   build/g86m --jit --fb 1024x768 --disk images/disk-x.img --initrd images/initramfs-disk images/vmlinuz-lts
#   ~ # startx
#
# The tree is the one rustx86's X disk is made of (its tools/images/sh/make-x-root.sh:
# Alpine's Xorg with the fbdev and evdev drivers, icewm, xterm, dillo and a few more, with
# its configuration), which that project keeps as a squashfs; XROOT names it. Here it is
# unpacked, given g86m's init (tools/images/init) in place of its own, and put on ext2, which
# the guest can write. Run tools/images/make-disk.sh first, for the initramfs that finds the
# disk.
#
# The work is done in a Linux container, for unsquashfs and mke2fs. IMGTOOLS names the image;
# the default is the one rustx86's tools/images/Dockerfile builds.
set -e
cd "$(dirname "$0")/../.."
if [ ! -f /.dockerenv ]; then
    [ -f "${XROOT:-}" ] || { echo "make-x-disk: set XROOT to rustx86's images/disk-x.img" >&2; exit 1; }
    xroot=$(cd "$(dirname "$XROOT")" && pwd)/$(basename "$XROOT")
    exec docker run --rm -v "$PWD:/w" -v "$xroot:/xroot:ro" -w /w "${IMGTOOLS:-rustx86-imgtools}" sh tools/images/make-x-disk.sh
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unsquashfs -q -f -d "$work/root" /xroot >/dev/null
[ -x "$work/root/usr/bin/Xorg" ] || { echo "make-x-disk: no Xorg in the tree" >&2; exit 1; }
rm -f "$work/root/.rustx86-disk"
touch "$work/root/.g86m-disk"
cp tools/images/init "$work/root/init"
chmod 755 "$work/root/init"
mkdir -p "$work/root/mnt" "$work/root/root"

rm -f images/disk-x.img
mke2fs -q -t ext2 -L g86m-x -E root_owner=0:0 -d "$work/root" images/disk-x.img 320M
ls -l images/disk-x.img
