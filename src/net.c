// The host side of the guest's network card (dev.goose): libslirp, a TCP/IP stack in user
// mode, which answers the guest's frames as a gateway, a DHCP server and a DNS server would
// and opens the host's own sockets for what the guest connects to. No root is needed.
//
// libslirp is opened when --net is given (dlopen), not linked, so a build needs nothing of
// it. The two structures below are libslirp's own (libslirp.h, version 1 of its
// configuration), declared here because nothing is included.
//
// Nothing here runs on its own: the run loop calls net_poll every so often, which lets
// libslirp look at its sockets and its timers; frames for the guest wait in a queue until
// the card takes them.

#include <dlfcn.h>
#include <netinet/in.h>
#include <poll.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>

typedef struct { const uint8_t *data; int64_t len; } net_bytes;
typedef struct { uint8_t *data; int64_t len; } net_buf;

typedef struct Slirp Slirp;
typedef void (*SlirpTimerCb)(void *opaque);
typedef struct {
    ssize_t (*send_packet)(const void *buf, size_t len, void *opaque);
    void (*guest_error)(const char *msg, void *opaque);
    int64_t (*clock_get_ns)(void *opaque);
    void *(*timer_new)(SlirpTimerCb cb, void *cb_opaque, void *opaque);
    void (*timer_free)(void *timer, void *opaque);
    void (*timer_mod)(void *timer, int64_t expire_time, void *opaque);
    void (*register_poll_fd)(int fd, void *opaque);
    void (*unregister_poll_fd)(int fd, void *opaque);
    void (*notify)(void *opaque);
} SlirpCb;
typedef struct {
    uint32_t version;
    int restricted;
    bool in_enabled;
    struct in_addr vnetwork;
    struct in_addr vnetmask;
    struct in_addr vhost;
    bool in6_enabled;
    struct in6_addr vprefix_addr6;
    uint8_t vprefix_len;
    struct in6_addr vhost6;
    const char *vhostname;
    const char *tftp_server_name;
    const char *tftp_path;
    const char *bootfile;
    struct in_addr vdhcp_start;
    struct in_addr vnameserver;
    struct in6_addr vnameserver6;
    const char **vdnssearch;
    const char *vdomainname;
    size_t if_mtu;
    size_t if_mru;
    bool disable_host_loopback;
    bool enable_emu;
} SlirpConfig;

static Slirp *slirp;
static void (*slirp_input)(Slirp *, const uint8_t *, int);
static void (*slirp_pollfds_fill)(Slirp *, uint32_t *, int (*)(int, int, void *), void *);
static void (*slirp_pollfds_poll)(Slirp *, int, int (*)(int, void *), void *);

// Frames for the guest, oldest first.
#define QUEUE 256
#define FRAME 1600
static uint8_t queue[QUEUE][FRAME];
static int queue_len[QUEUE];
static int queue_head, queue_count;

static ssize_t to_guest(const void *buf, size_t len, void *opaque) {
    (void)opaque;
    if (len > FRAME || queue_count == QUEUE) return (ssize_t)len;      // dropped: TCP sends again
    int at = (queue_head + queue_count) % QUEUE;
    memcpy(queue[at], buf, len);
    queue_len[at] = (int)len;
    queue_count++;
    return (ssize_t)len;
}

static void guest_error(const char *msg, void *opaque) { (void)msg; (void)opaque; }

static int64_t now_ns(void *opaque) {
    (void)opaque;
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000 + ts.tv_nsec;
}

// libslirp's timers: each has a time to go off at, in milliseconds on the clock above, or
// none.
typedef struct Timer { SlirpTimerCb cb; void *opaque; int64_t at; struct Timer *next; } Timer;
static Timer *timers;

static void *timer_new(SlirpTimerCb cb, void *cb_opaque, void *opaque) {
    (void)opaque;
    Timer *t = calloc(1, sizeof *t);
    if (!t) return 0;
    t->cb = cb;
    t->opaque = cb_opaque;
    t->at = -1;
    t->next = timers;
    timers = t;
    return t;
}

static void timer_free(void *timer, void *opaque) {
    (void)opaque;
    for (Timer **p = &timers; *p; p = &(*p)->next) {
        if (*p == timer) { *p = (*p)->next; free(timer); return; }
    }
}

static void timer_mod(void *timer, int64_t expire_time, void *opaque) {
    (void)opaque;
    ((Timer *)timer)->at = expire_time;
}

static void poll_fd(int fd, void *opaque) { (void)fd; (void)opaque; }
static void notify(void *opaque) { (void)opaque; }

static const SlirpCb callbacks = { to_guest, guest_error, now_ns, timer_new, timer_free, timer_mod, poll_fd, poll_fd, notify };

// Opens libslirp and makes the network 10.0.2.0/24, with the host at 10.0.2.2, a name
// server at 10.0.2.3 and addresses given out from 10.0.2.15: what QEMU's user network is.
// Returns 0, or -1 if the library is not there or will not start.
int32_t net_open(void) {
    static const char *names[] = { "/opt/homebrew/lib/libslirp.dylib", "/usr/local/lib/libslirp.dylib",
                                   "libslirp.dylib", "libslirp.so.0", 0 };
    void *lib = 0;
    for (int i = 0; names[i] && !lib; i++) lib = dlopen(names[i], RTLD_NOW);
    if (!lib) return -1;
    Slirp *(*slirp_new)(const SlirpConfig *, const SlirpCb *, void *) = dlsym(lib, "slirp_new");
    slirp_input = dlsym(lib, "slirp_input");
    slirp_pollfds_fill = dlsym(lib, "slirp_pollfds_fill");
    slirp_pollfds_poll = dlsym(lib, "slirp_pollfds_poll");
    if (!slirp_new || !slirp_input || !slirp_pollfds_fill || !slirp_pollfds_poll) return -1;
    SlirpConfig cfg;
    memset(&cfg, 0, sizeof cfg);
    cfg.version = 1;
    cfg.in_enabled = true;
    cfg.vnetwork.s_addr = htonl(0x0A000200);
    cfg.vnetmask.s_addr = htonl(0xFFFFFF00);
    cfg.vhost.s_addr = htonl(0x0A000202);
    cfg.vdhcp_start.s_addr = htonl(0x0A00020F);
    cfg.vnameserver.s_addr = htonl(0x0A000203);
    cfg.vhostname = "g86m";
    slirp = slirp_new(&cfg, &callbacks, 0);
    return slirp ? 0 : -1;
}

// A frame from the guest.
void net_send(net_bytes frame) {
    if (slirp && frame.len > 0) slirp_input(slirp, frame.data, (int)frame.len);
}

// The sockets libslirp wants looked at, for one poll().
#define FDS 256
static struct pollfd fds[FDS];
static int fd_count;

// libslirp's event bits are 1 in, 2 out, 4 urgent, 8 error, 16 hung up.
static int add_poll(int fd, int events, void *opaque) {
    (void)opaque;
    if (fd_count == FDS) return -1;
    short e = 0;
    if (events & 1) e |= POLLIN;
    if (events & 2) e |= POLLOUT;
    if (events & 4) e |= POLLPRI;
    fds[fd_count].fd = fd;
    fds[fd_count].events = e;
    fds[fd_count].revents = 0;
    return fd_count++;
}

static int get_revents(int idx, void *opaque) {
    (void)opaque;
    if (idx < 0 || idx >= fd_count) return 0;
    short r = fds[idx].revents;
    int e = 0;
    if (r & POLLIN) e |= 1;
    if (r & POLLOUT) e |= 2;
    if (r & POLLPRI) e |= 4;
    if (r & POLLERR) e |= 8;
    if (r & POLLHUP) e |= 16;
    return e;
}

// Lets libslirp do what is due: its sockets, without waiting, and its timers.
void net_poll(void) {
    if (!slirp) return;
    uint32_t timeout = 0;
    fd_count = 0;
    slirp_pollfds_fill(slirp, &timeout, add_poll, 0);
    int r = poll(fds, (nfds_t)fd_count, 0);
    slirp_pollfds_poll(slirp, r < 0, get_revents, 0);
    int64_t ms = now_ns(0) / 1000000;
    // A timer's function may make and free timers: the list is looked through afresh after
    // each one that goes off.
    for (Timer *t = timers; t; ) {
        if (t->at >= 0 && t->at <= ms) { t->at = -1; t->cb(t->opaque); t = timers; } else { t = t->next; }
    }
}

// The oldest frame for the guest into buf. Returns its length, or 0 if none is waiting.
int32_t net_recv(net_buf buf) {
    if (queue_count == 0) return 0;
    int len = queue_len[queue_head];
    if (len > buf.len) len = (int)buf.len;
    memcpy(buf.data, queue[queue_head], (size_t)len);
    queue_head = (queue_head + 1) % QUEUE;
    queue_count--;
    return len;
}
