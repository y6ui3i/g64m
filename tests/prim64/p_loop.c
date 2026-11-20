// Loops: counting up and down, one inside another, with a sum carried round.
// flags: int
#include "prim.h"
NOINLINE static u64 run(u64 n, u64 m) {
    u64 s = 0;
    for (u64 i = 0; i < n; i++) {
        for (u64 j = m; j != 0; j--) s += i ^ j;
        s += s >> 3;
    }
    return s;
}
int main(void) {
    put("loop", run(3000, 1000));
    return 0;
}
