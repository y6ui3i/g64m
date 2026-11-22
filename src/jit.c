// The C a Goose program needs to run code it generated (E058, E059): memory that may be
// executed, a copy into it, and a call. Everything else of the JIT is in jit.goose.
//
// On macOS for arm64 a mapping made with MAP_JIT is either writable or executable for the
// calling thread, never both, so the copy switches it over and back; and the instruction cache
// is told what changed.

#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#ifdef __APPLE__
#include <pthread.h>
#include <libkern/OSCacheControl.h>
#endif

typedef struct { const uint8_t *data; int64_t len; } jit_bytes;
typedef struct { uint32_t *data; int64_t len; } jit_regs;

// The time, in nanoseconds of a clock that only goes forward (--jit-time, E141).
int64_t jit_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

// Maps size bytes that can hold code. Returns the address, or 0; 0 always on a host that is
// not arm64, for which jit.goose generates nothing (so --jit does nothing there).
int64_t jit_alloc(int64_t size) {
#if !defined(__aarch64__)
    (void)size;
    return 0;
#else
    int flags = MAP_PRIVATE | MAP_ANONYMOUS;
#ifdef __APPLE__
    flags |= MAP_JIT;
#endif
    void *p = mmap(0, (size_t)size, PROT_READ | PROT_WRITE | PROT_EXEC, flags, -1, 0);
    return p == MAP_FAILED ? 0 : (int64_t)p;
#endif
}

// Copies code to address at, inside a mapping from jit_alloc.
void jit_write(int64_t at, jit_bytes code) {
#ifdef __APPLE__
    pthread_jit_write_protect_np(0);
#endif
    memcpy((void *)at, code.data, (size_t)code.len);
#ifdef __APPLE__
    pthread_jit_write_protect_np(1);
    sys_icache_invalidate((void *)at, (size_t)code.len);
#else
    __builtin___clear_cache((char *)at, (char *)at + code.len);
#endif
}

// Calls the way into generated code (jit.goose, jit_init) for the block at code: the address of
// the guest's registers, of RAM, of the TLB and of seg_top, pbase, the time and the virtual
// time. Generated code comes back with two values: what the Goose program gets (the next
// address, and above it the count of instructions executed), and the address of the link slot
// it left through or 0, which is kept here for jit_slot.
typedef struct { int64_t next; int64_t slot; } jit_back;
static int64_t jit_slot_was;

int64_t jit_call(int64_t enter, jit_regs regs, int64_t ram, int64_t tlb, int64_t seg, int64_t pbase, int64_t code, int64_t time, int64_t vt) {
    jit_back b = ((jit_back (*)(uint32_t *, int64_t, int64_t, int64_t, int64_t, int64_t, int64_t, int64_t))enter)(regs.data, ram, tlb, seg, pbase, code, time, vt);
    jit_slot_was = b.slot;
    return b.next;
}

int64_t jit_slot(void) { return jit_slot_was; }

// Where an array of the Goose program is.
typedef struct { const uint32_t *data; int64_t len; } jit_words;
int64_t jit_addr8(jit_bytes a) { return (int64_t)a.data; }
int64_t jit_addr32(jit_words a) { return (int64_t)a.data; }
typedef struct { const int64_t *data; int64_t len; } jit_quads;
int64_t jit_addr64(jit_quads a) { return (int64_t)a.data; }

// For the 64-bit CPU's JIT (jit64.goose): where an array of 64-bit values is, and a call
// into generated code with four values.
typedef struct { const uint64_t *data; int64_t len; } jit_uquads;
int64_t jit_addr_u64(jit_uquads a) { return (int64_t)a.data; }
int64_t jit_call4(int64_t enter, int64_t a, int64_t b, int64_t c, int64_t d) {
    return ((int64_t (*)(int64_t, int64_t, int64_t, int64_t))enter)(a, b, c, d);
}

// Where an array of structures is, and the 64 bits at an address (jit64.goose checks with
// it that the decode cache is laid out as its generated code reads it).
typedef struct { const void *data; int64_t len; } jit_any;
int64_t jit_addr_any(jit_any a) { return (int64_t)a.data; }
int64_t jit_peek64(int64_t at) { return *(const int64_t *)at; }
