#!/bin/sh
# run.sh MODE WORK K : MODE q = under qemu-x86_64 -L /r, n = natively in the amd64 container
M=$1; WK=$2; K=${3:-1}
if [ "$M" = q ]; then P="qemu-x86_64 $QOPT -L /r"; R=/r; else P=""; R=""; fi
CC1=/usr/libexec/gcc/x86_64-alpine-linux-musl/14.2.0/cc1
cd /tmp
t0=$(cut -d" " -f1 /proc/uptime)
case $WK in
  sh)   $P $R/bin/busybox sh -c "i=0; while [ \$i -lt $((100000*K)) ]; do i=\$((i+1)); done" ;;
  gzip) $P $R/bin/busybox seq 1 $((400000*K)) | $P $R/bin/busybox gzip -c | wc -c ;;
  sha)  head -c $((20000000*K)) /dev/zero > z; $P $R/bin/busybox sha256sum z ;;
  py)   $P $R/usr/local/bin/python3 /w/bench.py $K ;;
  node) $P $R/usr/local/bin/node $NODEOPT /w/bench.js $K ;;
  gcc)  for f in /w/p_*.c; do $P $R$CC1 -quiet -O2 -I/w $f -o x.s && $P $R/usr/bin/as x.s -o x.o || echo FAIL $f; done; [ $K -gt 1 ] && for f in /w/p_*.c; do $P $R$CC1 -quiet -O2 -I/w $f -o x.s; done ;;
  redis) $P $R/usr/local/bin/redis-server --save '' --port 6399 >/dev/null & s=$!; sleep 1; t0=$(cut -d" " -f1 /proc/uptime)
         $P $R/usr/local/bin/redis-benchmark -p 6399 -q -n $((20000*K)) -t set,get,lpush,lrange_100 | tr '\r' '\n' | grep -v '^$' | tail -4; kill $s ;;
esac
t1=$(cut -d" " -f1 /proc/uptime)
echo "TIME $M $WK $K $(awk "BEGIN{print $t1-$t0}")"
