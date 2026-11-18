// The file behind the guest's disk (dev.goose, the IDE disk): opened once, then read and
// written in place, a sector at a time, so that what the guest has written is in the file
// when the write returns (--keep). Or, as it is unless --keep is given, never written at all:
// the guest's writes stay in this process (E081, E084).

#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

typedef struct { const uint8_t *data; int64_t len; } disk_bytes;
typedef struct { uint8_t *data; int64_t len; } disk_buf;

static int disk_fd = -1;
// Without --keep: the image mapped privately, so that what is written goes to memory of this
// process (a copy of the page written) and never to the file.
static uint8_t *disk_map;
static int64_t disk_bytes_n;

// Opens the image. Returns how many 512-byte sectors it has, or -1. With scratch, nothing the
// guest writes reaches the file.
int64_t disk_open(disk_bytes path, int32_t scratch) {
    char name[1024];
    if (path.len <= 0 || path.len >= (int64_t)sizeof name) return -1;
    memcpy(name, path.data, (size_t)path.len);
    name[path.len] = 0;
    disk_fd = open(name, scratch ? O_RDONLY : O_RDWR);
    if (disk_fd < 0) return -1;
    off_t end = lseek(disk_fd, 0, SEEK_END);
    if (end < 512) return -1;
    if (scratch) {
        void *p = mmap(0, (size_t)end, PROT_READ | PROT_WRITE, MAP_PRIVATE, disk_fd, 0);
        if (p == MAP_FAILED) return -1;
        disk_map = p;
        disk_bytes_n = (int64_t)end;
    }
    return (int64_t)(end / 512);
}

// Reads buf.len bytes from sector lba on; 0 if all of them were read.
int32_t disk_read(int64_t lba, disk_buf buf) {
    if (disk_map) {
        if (lba < 0 || lba * 512 + buf.len > disk_bytes_n) return -1;
        memcpy(buf.data, disk_map + lba * 512, (size_t)buf.len);
        return 0;
    }
    return pread(disk_fd, buf.data, (size_t)buf.len, (off_t)lba * 512) == (ssize_t)buf.len ? 0 : -1;
}

// Writes buf.len bytes from sector lba on; 0 if all of them were written.
int32_t disk_write(int64_t lba, disk_bytes buf) {
    if (disk_map) {
        if (lba < 0 || lba * 512 + buf.len > disk_bytes_n) return -1;
        memcpy(disk_map + lba * 512, buf.data, (size_t)buf.len);
        return 0;
    }
    return pwrite(disk_fd, buf.data, (size_t)buf.len, (off_t)lba * 512) == (ssize_t)buf.len ? 0 : -1;
}
