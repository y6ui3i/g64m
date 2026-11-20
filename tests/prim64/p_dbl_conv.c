// double: to and from whole numbers of 32 and 64 bits, with and without a sign, and to
// and from float.
// flags: sse
#include "prim.h"
static i64 a[1024];
NOINLINE static u64 run(const i64 *x, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) {
        double d = (double)x[i];
        double e = (double)(i32)x[i] * 1.5;
        double f = (double)(u32)x[i];
        float g = (float)d;
        s += (u64)(i64)(d * 0.25);
        s ^= (u64)(i32)e;
        s += (u32)f;
        s ^= (u64)(i64)((double)g / 3.0);
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) a[i] = (i64)next() >> 20;
    u64 s = 0;
    // Each round changes what the next works on, so that none can be left out.
    for (int k = 0; k < 1500; k++) { a[k & 1023] ^= (i64)(s & 0xFFFFF); s += run(a, 1024); }
    put("dbl_conv", s);
    return 0;
}
