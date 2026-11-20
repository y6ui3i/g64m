// Multiplying and dividing by numbers that are not known when it is compiled: 32 and 64
// bits, with and without a sign, and the remainder.
// flags: int
#include "prim.h"
static u64 a[1024], b[1024];
NOINLINE static u64 run(const u64 *x, const u64 *y, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) {
        u64 p = x[i], q = y[i] | 1;
        s += p * q;
        s ^= p / q;
        s += p % q;
        s ^= (u64)((i64)p / (i64)q);
        s += (u32)p * (u32)q;
        s ^= (u32)p / ((u32)q | 1);
        s += (u64)((i32)p % (i32)((u32)q | 1));
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) { a[i] = next(); b[i] = next() >> (next() & 31); }
    u64 s = 0;
    // Each round changes what the next works on, so that none can be left out.
    for (int k = 0; k < 1000; k++) { a[k & 1023] += s; s += run(a, b, 1024); }
    put("muldiv", s);
    return 0;
}
