// Bits: a structure whose members are a few bits each, read and written.
// flags: int
#include "prim.h"
struct packed { u32 kind : 3; u32 level : 5; i32 delta : 9; u32 flag : 1; u32 count : 14; };
static struct packed recs[1024];
NOINLINE static u64 run(struct packed *r, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) {
        struct packed *p = &r[i];
        p->count += p->kind;
        p->level ^= p->count;
        p->delta -= 3;
        p->flag = p->delta < 0;
        s += p->level + p->delta + (p->flag ? p->count : p->kind);
    }
    return s;
}
int main(void) {
    for (int i = 0; i < 1024; i++) { u64 v = next(); recs[i].kind = v; recs[i].level = v >> 8; recs[i].delta = v >> 16; recs[i].count = v >> 32; }
    u64 s = 0;
    for (int k = 0; k < 1500; k++) s += run(recs, 1024);
    put("bitfield", s);
    return 0;
}
