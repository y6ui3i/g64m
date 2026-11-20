// Arrays and structures: an element by its number, a field of an element, and a table of
// rows and columns.
// flags: int
#include "prim.h"
struct rec { u32 key; u16 kind; u8 flag; u8 pad; u64 total; };
static struct rec recs[1024];
static u32 grid[64][64];
static u16 order[1024];
NOINLINE static u64 fields(struct rec *r, const u16 *o, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) {
        struct rec *p = &r[o[i]];
        p->total += p->key + p->kind;
        p->flag ^= 1;
        s += r[i].total >> r[i].flag;
    }
    return s;
}
NOINLINE static u64 table(u32 g[64][64]) {
    u64 s = 0;
    for (int y = 1; y < 63; y++)
        for (int x = 1; x < 63; x++) {
            g[y][x] += g[y - 1][x] ^ g[y][x - 1];
            s += g[x][y];
        }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) { u64 r = next(); recs[i].key = r; recs[i].kind = r >> 32; order[i] = r >> 50 & 1023; }
    for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) grid[y][x] = next();
    u64 s = 0, t = 0;
    for (int k = 0; k < 600; k++) { s += fields(recs, order, 1024); t += table(grid); }
    put("fields", s);
    put("table", t);
    return 0;
}
