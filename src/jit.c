// The C a Goose program needs to run code it generated (E058, E059): memory that may be
// executed, a copy into it, and a call. Everything else of the JIT is in jit.goose.
//
// On macOS for arm64 a mapping made with MAP_JIT is either writable or executable for the
// calling thread, never both, so the copy switches it over and back; and the instruction cache
// is told what changed.

#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#ifdef __APPLE__
#include <pthread.h>
#include <libkern/OSCacheControl.h>
#endif

typedef struct { const uint8_t *data; int64_t len; } jit_bytes;
typedef struct { uint32_t *data; int64_t len; } jit_regs;

// Maps size bytes that can hold code. Returns the address, or 0.
int64_t jit_alloc(int64_t size) {
    int flags = MAP_PRIVATE | MAP_ANONYMOUS;
#ifdef __APPLE__
    flags |= MAP_JIT;
#endif
    void *p = mmap(0, (size_t)size, PROT_READ | PROT_WRITE | PROT_EXEC, flags, -1, 0);
    return p == MAP_FAILED ? 0 : (int64_t)p;
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
// the guest's registers, of RAM, of the TLB and of seg_top, and pbase. Returns what the block
// returns.
int64_t jit_call(int64_t enter, jit_regs regs, int64_t ram, int64_t tlb, int64_t seg, int64_t pbase, int64_t code) {
    return ((int64_t (*)(uint32_t *, int64_t, int64_t, int64_t, int64_t, int64_t))enter)(regs.data, ram, tlb, seg, pbase, code);
}

// Where an array of the Goose program is.
typedef struct { const uint32_t *data; int64_t len; } jit_words;
int64_t jit_addr8(jit_bytes a) { return (int64_t)a.data; }
int64_t jit_addr32(jit_words a) { return (int64_t)a.data; }
