#!/bin/sh
# Makes images/disk64-nh.img: the 64-bit machine's disk (make-disk.sh) with NetHack 3.6.7 on
# it, built on a real x86_64 Linux host and run in the guest as it is (E115).
#
#   ORACLE_HOST=name MODLOOP=images/modloop64-lts tools/images/make-nethack.sh
#   build/x64 --disk images/disk64-nh.img --initrd images/initramfs64-disk images/vmlinuz64-lts
#   and in the guest:  /nh/nethack
#
# On the host of that ssh name, in ~/g86m-oracle/nethack: the source is fetched from
# nethack.org if it is not there (nethack-367-src.tgz, 5.6 MB), and built with the host's GCC,
# linked statically against its C library and ncurses, to live in /nh. The host needs
# libncurses-dev; the parsers NetHack ships ready-made are used, so it needs no yacc or lex.
#
# Besides the program the disk gets what a statically linked program still looks for:
# four terminal descriptions (the host's, from /usr/share/terminfo) and an /etc/passwd.
#
# Neither NetHack nor the image is in this repository.
set -e
cd "$(dirname "$0")/../.."
[ -n "${ORACLE_HOST:-}" ] || { echo "make-nethack: set ORACLE_HOST to an x86_64 Linux host" >&2; exit 1; }
V=NetHack-3.6.7
ssh "$ORACLE_HOST" "set -e
mkdir -p g86m-oracle/nethack && cd g86m-oracle/nethack
[ -f nethack-367-src.tgz ] || curl -sSLO https://www.nethack.org/download/3.6.7/nethack-367-src.tgz
echo '98cf67df6debf9668a61745aa84c09bcab362e5d33f5b944ec5155d44d2aacb2  nethack-367-src.tgz' | sha256sum -c --quiet
rm -rf $V stage && tar xzf nethack-367-src.tgz && cd $V
# The Linux hints, with: /nh as its home, a static link, -O2, and the C of its time (GCC 15
# takes C23 otherwise, which this source is not).
sed -e 's|^PREFIX=.*|PREFIX=/nh|' -e 's|^HACKDIR=.*|HACKDIR=/nh|' -e 's|^SHELLDIR = .*|SHELLDIR = /nh/bin|' \
    -e 's|^CFLAGS=-g -O |CFLAGS=-O2 -std=gnu17 -w |' -e 's|^LFLAGS=-rdynamic|LFLAGS=-static|' sys/unix/hints/linux > sys/unix/hints/g86m
(cd sys/unix && sh setup.sh hints/g86m)
cp sys/share/dgn_yacc.c sys/share/lev_yacc.c sys/share/dgn_lex.c sys/share/lev_lex.c util/
cp sys/share/dgn_comp.h sys/share/lev_comp.h include/
make all > ../build.log 2>&1
# Installed beside the source, not in /nh: where it is put is not where it will live.
S=\$HOME/g86m-oracle/nethack/stage/nh
mkdir -p \$S/bin
make install HACKDIR=\$S SHELLDIR=\$S/bin INSTDIR=\$S VARDIR=\$S > ../install.log 2>&1 || true
[ -x \$S/nethack ] && [ -f \$S/nhdat ]
rm -rf \$S/bin
cp sys/unix/sysconf \$S/sysconf
touch \$S/perm \$S/record \$S/logfile \$S/xlogfile
chmod 666 \$S/perm \$S/record \$S/logfile \$S/xlogfile && chmod 777 \$S/save
mkdir -p ../stage/usr/share/terminfo ../stage/etc
for t in x/xterm v/vt100 l/linux a/ansi; do mkdir -p ../stage/usr/share/terminfo/\${t%/*}; cp /usr/share/terminfo/\$t ../stage/usr/share/terminfo/\$t; done
printf 'root:x:0:0:root:/root:/bin/sh\n' > ../stage/etc/passwd
printf 'root:x:0:\ngames:x:60:\n' > ../stage/etc/group
cd ../stage && tar czf ../nh-stage.tgz ."
rm -rf build/nhroot && mkdir -p build/nhroot
scp -q "$ORACLE_HOST:g86m-oracle/nethack/nh-stage.tgz" build/nh-stage.tgz
tar xzf build/nh-stage.tgz -C build/nhroot
# make-disk.sh makes the initramfs again too; the one that is there is kept.
cp images/initramfs64-disk build/initramfs64-disk.keep
ARCH=64 EXTRA=build/nhroot SIZE=64M OUT=images/disk64-nh.img tools/images/make-disk.sh
cp build/initramfs64-disk.keep images/initramfs64-disk
ls -l images/disk64-nh.img
