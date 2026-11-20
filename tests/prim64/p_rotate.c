// Bits: rotating, the place of the lowest and of the highest set bit, one bit tested and
// set by its number, and the count of set bits.
// flags: int
#include "prim.h"
static u64 a[1024];
static u64 map[64];
NOINLINE static u64 run(const u64 *x, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) {
        u64 v = x[i] | 1;
        unsigned k = v >> 58;
        s += v << 13 | v >> 51;
        s ^= v >> k | v << (-k & 63);
        s += __builtin_ctzl(v) + __builtin_clzl(v);
        s ^= (u32)v << 7 | (u32)v >> 25;
        if (map[v >> 6 & 63] >> (v & 63) & 1) s++;
        map[v >> 12 & 63] |= 1UL << (v >> 20 & 63);
        u64 c = v; int bits = 0;
        while (c) { c &= c - 1; bits++; }
        s += bits;
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) a[i] = next();
    u64 s = 0;
    for (int k = 0; k < 500; k++) s += run(a, 1024);
    put("rotate", s);
    return 0;
}
