// double: comparisons that decide a jump, the smaller and larger of two, and a search.
// flags: sse
#include "prim.h"
static double a[1024];
static u64 count[4];
NOINLINE static double run(const double *x, int n) {
    double lo = x[0], hi = x[0];
    for (int i = 0; i < n; i++) {
        double v = x[i];
        if (v < 100.0) count[0]++;
        else if (v <= 1000.0) count[1] += i;
        else if (v != v) count[2]++;
        else count[3] ^= i;
        if (v < lo) lo = v;
        if (v > hi) hi = v;
    }
    return hi - lo;
}
int main(void) {
    for (int i = 0; i < 1024; i++) a[i] = (double)(next() >> 52) * 0.75;
    double s = 0.0;
    for (int k = 0; k < 2000; k++) s += run(a, 1024);
    union { double d; u64 u; } v = { s };
    put("dbl_cmp", v.u);
    for (int i = 0; i < 4; i++) put("count", count[i]);
    return 0;
}
