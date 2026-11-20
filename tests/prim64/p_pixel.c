// Pixels, one at a time: a picture of 256 by 256 put over another with its transparency,
// each colour of each pixel worked out by itself.
// flags: int
#include "prim.h"
static u32 under[256 * 256], over[256 * 256];
NOINLINE static void blend(u32 *d, const u32 *s, int n) {
    for (int i = 0; i < n; i++) {
        u32 a = s[i] >> 24, na = 255 - a;
        u32 r = ((s[i] >> 16 & 255) * a + (d[i] >> 16 & 255) * na + 127) / 255;
        u32 g = ((s[i] >> 8 & 255) * a + (d[i] >> 8 & 255) * na + 127) / 255;
        u32 b = ((s[i] & 255) * a + (d[i] & 255) * na + 127) / 255;
        u32 sum = (d[i] >> 24) + a;
        d[i] = (sum > 255 ? 255 : sum) << 24 | r << 16 | g << 8 | b;
    }
}
int main(void) {
    for (int i = 0; i < 256 * 256; i++) { under[i] = next(); over[i] = next(); }
    for (int k = 0; k < 8; k++) blend(under, over, 256 * 256);
    u64 s = 0;
    for (int i = 0; i < 256 * 256; i++) s += under[i];
    put("pixel", s);
    return 0;
}
