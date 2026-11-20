// Bits: shifts by a constant and by a variable, masks, NOT and the negative.
// flags: int
#include "prim.h"
static u64 a[1024];
NOINLINE static u64 run(const u64 *x, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) {
        u64 v = x[i];
        unsigned k = v & 63;
        s += v << 7 ^ v >> 11;
        s ^= v << k | (u64)((i64)v >> (k >> 1));
        s += ~v & 0x00FF00FF00FF00FF;
        s ^= -v & v;
        s += (u32)v >> (k & 31) ^ (u32)((i32)(u32)v >> 5);
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) a[i] = next();
    u64 s = 0;
    // Each round changes what the next works on, so that none can be left out.
    for (int k = 0; k < 2000; k++) { a[k & 1023] ^= s; s += run(a, 1024); }
    put("shift", s);
    return 0;
}
