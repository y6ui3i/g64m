#!/bin/sh
# Where the globals are. Goose packs globals into one block with no padding, so a global can
# sit at any address, and one byte added in front moves every global behind it. The ones the
# interpreter's inner loop reads and writes are kept at multiples of 8 by pads (pad_... in
# src/); this shows whether they still are (E050).
#
#   tools/layout.sh                  list the watched globals: offset in the block, modulo 8
#   tools/layout.sh --check          the same, and fail if one is off its alignment
#   tools/layout.sh name[:align]...  list these instead (align is 8 unless given)
#   PROG=g64m tools/layout.sh ...    the 64-bit machine's block (E173: its scalars first, its
#                                    arrays at the end and on lines of the cache)
#
# It reads the C that the last `goose build` of g86m generated (under GOOSE_HOME, ~/.goose by
# default) and asks the C compiler for offsetof() of each. Build first.
set -u
check=0
if [ "${1:-}" = "--check" ]; then check=1; shift; fi
prog="${PROG:-g86m}"
if [ $# -eq 0 ] && [ "$prog" = g64m ]; then
    set -- jx reg rip rflags steps ip ins code_page dc_cur rep_until pending \
        tlb_tag:64 bt_tag:64 jt:64 dc:64 dc_n:64 dc_code:64 mem:64
fi
if [ $# -eq 0 ]; then
    set -- timer_at ins ea_seg ea_off dc_cur chain_until light_save cpu saved seg_top cr:4 \
        code_page:4 code_phys:4 tlb_rtag:4 tlb_rphys:4 tlb_wtag:4 tlb_wphys:4 ram dc dc_next:4 vtime
fi
src=$(ls -t "${GOOSE_HOME:-$HOME/.goose}"/build/prog/$prog-*/$prog.c 2>/dev/null | head -1)
if [ -z "$src" ]; then echo "layout: no generated C found; run goose build first" >&2; exit 2; fi
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
{
    echo '#define main gs_main_not_used'
    cat "$src"
    for spec in "$@"; do
        n=${spec%%:*}
        echo "const long gs_off_$n = __builtin_offsetof(gs_globals_t, ${n}_g);"
    done
} > "$tmp/l.c"
${CC:-cc} -O0 -w -S -o "$tmp/l.s" "$tmp/l.c" || exit 2
bad=0
for spec in "$@"; do
    n=${spec%%:*}
    case "$spec" in *:*) al=${spec##*:} ;; *) al=8 ;; esac
    off=$(awk -v n="_gs_off_$n:" '$1 == n { getline; print $2 }' "$tmp/l.s")
    if [ -z "$off" ]; then echo "layout: $n not found" >&2; bad=1; continue; fi
    rem=$((off % al))
    if [ $check -eq 0 ]; then printf '%-12s %10d  modulo %d = %d\n' "$n" "$off" "$al" "$rem"; fi
    if [ $rem -ne 0 ]; then
        bad=1
        [ $check -eq 1 ] && echo "layout: $n is at $off, $rem past a multiple of $al"
    fi
done
[ $check -eq 1 ] && exit $bad
exit 0
