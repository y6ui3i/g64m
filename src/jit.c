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

// Calls the code at fn with the address of the guest's registers in x0. Returns what it returns.
int64_t jit_call(int64_t fn, jit_regs regs) {
    return ((int64_t (*)(uint32_t *))fn)(regs.data);
}
