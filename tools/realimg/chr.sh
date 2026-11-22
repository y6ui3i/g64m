#!/bin/sh
# chr.sh ROOT WORK K OUT : the workload in a chroot of ROOT, under perf, all children followed.
R=$1; sudo -n mount --bind $HOME/e136/w $R/w; sudo -n mount -t proc proc $R/proc 2>/dev/null; sudo -n mount --bind /dev $R/dev
sudo -n perf record -q -e instructions:u -c 20011 -o $4 -- sudo -n chroot $R env GLIBC_TUNABLES=glibc.cpu.hwcaps=-AVX,-AVX2,-AVX_Usable,-AVX2_Usable,-AVX_Fast_Unaligned_Load NODEOPT=--no-enable-avx PATH=/usr/local/bin:/usr/bin:/bin sh /w/run.sh n $2 $3 | tail -1
sudo -n umount $R/proc; sudo -n umount $R/dev; sudo -n umount $R/w
