// long double: the four operations and a comparison, which are the x87's.
// flags: sse
#include "prim.h"
static long double a[512], b[512];
NOINLINE static long double run(const long double *x, const long double *y, int n) {
    long double s = 0.0L;
    for (int i = 0; i < n; i++) {
        long double t = x[i] * y[i] + s;
        t = t / (y[i] + 2.0L) - x[i];
        s = t > 8.0L ? s * 0.5L : s + t;
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 512; i++) { a[i] = (long double)(next() >> 40) / 4096.0L; b[i] = (long double)(next() >> 44) + 1.0L; }
    long double s = 0.0L;
    // Each round changes what the next works on, so that none can be left out.
    for (int k = 0; k < 1500; k++) { a[k & 511] = s * 0.001L + (long double)k; s += run(a, b, 512); }
    union { long double d; u64 u[2]; } v = { 0 };
    v.d = s;
    put("ldbl", v.u[0]);
    put("ldbl_hi", v.u[1] & 0xFFFF);
    return 0;
}
