#!/bin/sh
# Makes what M6's Linux boot needs beyond the kernel (docs/roadmap.md):
#
#   images/initramfs-disk   an initramfs with busybox, the IDE disk's driver and ext2 as
#                           modules, and an init that moves to the disk if there is one
#   images/disk.img         a 32 MB ext2 file system: the same busybox, as a root
#
#   MODLOOP=/path/to/modloop-lts tools/images/make-disk.sh
#   build/g86m --disk images/disk.img --initrd images/initramfs-disk images/vmlinuz-lts
#   (with --keep, what the guest writes stays in the image)
#
# With ARCH=64 the same for the 64-bit machine (E101), from Alpine's x86_64 files:
# images/initramfs64-mini gives busybox, MODLOOP is the x86_64 modloop-lts, and what is made
# is images/initramfs64-disk and images/disk64.img.
#   ARCH=64 MODLOOP=images/modloop64-lts tools/images/make-disk.sh
#   build/x64 --disk images/disk64.img --initrd images/initramfs64-disk images/vmlinuz64-lts
#
# EXTRA names a directory whose contents go into the disk's root as well (a program to run
# in the guest, say), SIZE the disk's size (32M), and OUT the image's name:
#   ARCH=64 MODLOOP=images/modloop64-lts EXTRA=build/nh SIZE=64M OUT=images/disk64-nh.img tools/images/make-disk.sh
#
# The kernel (Alpine's linux-lts) has the drivers only as modules. They are taken from
# Alpine's modloop-lts of the same kernel version, a squashfs of all its modules, so that
# they load; busybox and the C library are taken from images/initramfs-mini. Neither is in
# this repository.
#
# The work is done in a Linux container, for unsquashfs, cpio and mke2fs. IMGTOOLS names the
# image; the default is the one rustx86's tools/images/Dockerfile builds.
set -e
cd "$(dirname "$0")/../.."
if [ "${ARCH:-}" = 64 ]; then sfx=64; ld=ld-musl-x86_64.so.1; libc=libc.musl-x86_64.so.1; else sfx=""; ld=ld-musl-i386.so.1; libc=libc.musl-x86.so.1; fi
if [ ! -f /.dockerenv ]; then
    [ -f "${MODLOOP:-}" ] || { echo "make-disk: set MODLOOP to Alpine's modloop-lts" >&2; exit 1; }
    [ -f "images/initramfs$sfx-mini" ] || { echo "make-disk: images/initramfs$sfx-mini is not there" >&2; exit 1; }
    modloop=$(cd "$(dirname "$MODLOOP")" && pwd)/$(basename "$MODLOOP")
    exec docker run --rm -e ARCH="${ARCH:-}" -e EXTRA="${EXTRA:-}" -e SIZE="${SIZE:-}" -e OUT="${OUT:-}" -v "$PWD:/w" -v "$modloop:/modloop:ro" -w /w "${IMGTOOLS:-rustx86-imgtools}" sh tools/images/make-disk.sh
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/base" "$work/mods" "$work/ram" "$work/disk"
(cd "$work/base" && gunzip -c "/w/images/initramfs$sfx-mini" | cpio -idm --quiet 2>/dev/null)
[ -f "$work/base/bin/busybox" ] || { echo "make-disk: no busybox in images/initramfs$sfx-mini" >&2; exit 1; }

# The modules, by the names modules.dep gives them.
want="drivers/scsi/scsi_common drivers/scsi/scsi_mod drivers/ata/libata drivers/ata/pata_legacy drivers/scsi/sd_mod fs/mbcache fs/ext2/ext2"
for m in $want; do
    unsquashfs -q -f -d "$work/mods" /modloop "modules/*/kernel/$m.ko" >/dev/null
done

# What both roots share: busybox, the C library, an init, empty places to mount on.
tree() {
    mkdir -p "$1/bin" "$1/lib" "$1/proc" "$1/sys" "$1/dev" "$1/tmp" "$1/root" "$1/mnt"
    cp "$work/base/bin/busybox" "$1/bin/"
    cp "$work/base/lib/$ld" "$1/lib/"
    [ -e "$work/base/lib/$libc" ] && cp -P "$work/base/lib/$libc" "$1/lib/"
    cp tools/images/init "$1/init"
    cp tools/images/off "$1/bin/off"
    chmod 755 "$1/init" "$1/bin/busybox" "$1/bin/off"
}

tree "$work/ram"
mkdir -p "$work/ram/lib/modules"
find "$work/mods" -name '*.ko' -exec cp {} "$work/ram/lib/modules/" \;
n=$(ls "$work/ram/lib/modules" | wc -l)
[ "$n" -eq 7 ] || { echo "make-disk: $n of 7 modules found in the modloop" >&2; exit 1; }
(cd "$work/ram" && find . | cpio -o -H newc --quiet -R 0:0 | gzip -9) > "images/initramfs$sfx-disk"

tree "$work/disk"
touch "$work/disk/.g86m-disk"
if [ -n "${EXTRA:-}" ]; then cp -a "$EXTRA/." "$work/disk/"; fi
img="${OUT:-images/disk$sfx.img}"
rm -f "$img"
mke2fs -q -t ext2 -L g86m -E root_owner=0:0 -d "$work/disk" "$img" "${SIZE:-32M}"

ls -l "images/initramfs$sfx-disk" "$img"
