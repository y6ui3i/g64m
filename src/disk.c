// The file behind the guest's disk (dev.goose, the IDE disk): opened once, then read and
// written in place, a sector at a time, so that what the guest has written is in the file
// when the write returns.

#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

typedef struct { const uint8_t *data; int64_t len; } disk_bytes;
typedef struct { uint8_t *data; int64_t len; } disk_buf;

static int disk_fd = -1;

// Opens the image. Returns how many 512-byte sectors it has, or -1.
int64_t disk_open(disk_bytes path) {
    char name[1024];
    if (path.len <= 0 || path.len >= (int64_t)sizeof name) return -1;
    memcpy(name, path.data, (size_t)path.len);
    name[path.len] = 0;
    disk_fd = open(name, O_RDWR);
    if (disk_fd < 0) return -1;
    off_t end = lseek(disk_fd, 0, SEEK_END);
    return end < 0 ? -1 : (int64_t)(end / 512);
}

// Reads buf.len bytes from sector lba on; 0 if all of them were read.
int32_t disk_read(int64_t lba, disk_buf buf) {
    return pread(disk_fd, buf.data, (size_t)buf.len, (off_t)lba * 512) == (ssize_t)buf.len ? 0 : -1;
}

// Writes buf.len bytes from sector lba on; 0 if all of them were written.
int32_t disk_write(int64_t lba, disk_bytes buf) {
    return pwrite(disk_fd, buf.data, (size_t)buf.len, (off_t)lba * 512) == (ssize_t)buf.len ? 0 : -1;
}
