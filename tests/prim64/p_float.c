// float: the four operations and a comparison, as for double.
// flags: sse
#include "prim.h"
static float a[1024], b[1024], c[1024];
NOINLINE static float run(const float *x, const float *y, float *z, int n) {
    float s = 0.0f;
    for (int i = 0; i < n; i++) {
        float t = x[i] * y[i] + s;
        z[i] = t / (y[i] + 2.0f) - x[i];
        s = z[i] > 8.0f ? s * 0.5f : s + z[i];
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) { a[i] = (float)(next() >> 48) / 64.0f; b[i] = (float)(next() >> 52) + 1.0f; }
    float s = 0.0f;
    for (int k = 0; k < 1500; k++) s += run(a, b, c, 1024);
    union { float f; u32 u; } v = { s };
    put("float", v.u);
    return 0;
}
