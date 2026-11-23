// What the 64-bit CPU's JIT needs of C beside jit.c (E161): the address of a function of
// the Goose program that generated code calls.
#include <stdint.h>

extern uint64_t jit_x87(uint64_t w, uint64_t lo, uint64_t hi);
int64_t jit_x87_addr(void) { return (int64_t)&jit_x87; }
