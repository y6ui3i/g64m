// double: adding, taking away, multiplying and dividing, over arrays and in one chain.
// flags: sse
#include "prim.h"
static double a[1024], b[1024], c[1024];
NOINLINE static double run(const double *x, const double *y, double *z, int n) {
    double s = 0.0;
    for (int i = 0; i < n; i++) {
        double t = x[i] * y[i] + s;
        z[i] = t / (y[i] + 2.0) - x[i];
        s = s * 0.5 + z[i];
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) { a[i] = (double)(next() >> 40) / 4096.0; b[i] = (double)(next() >> 44) + 1.0; }
    double s = 0.0;
    for (int k = 0; k < 1500; k++) s += run(a, b, c, 1024);
    union { double d; u64 u; } v = { s };
    put("dbl_arith", v.u);
    return 0;
}
