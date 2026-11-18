// The window that shows the guest's frame buffer and takes the keyboard and the mouse for it
// (E078): SDL2, opened when --fb is given from a terminal (dlopen), not linked, so a build
// needs nothing of it. What is used of SDL2's interface is declared here: nine functions, the
// constants below, and where in an event its fields are.
//
// The run loop calls screen_show with the frame buffer every so often, and screen_poll for
// what was typed and moved, which comes back as numbers:
//   1 << 24 | code   a key: the PC keyboard's scan code (set 1), 100h for an E0 prefix
//                    before it, 200h for a release
//   2 << 24 | ...    the mouse moved: dx in bits 0 to 11 and dy in bits 12 to 23, signed
//   3 << 24 | bits   the mouse's buttons as they now are: 1 left, 2 right, 4 middle
//   4 << 24          the window was closed
// The pointer is the guest's while the window has it: a click in the window takes it, and
// Ctrl+Alt gives it back.

#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

typedef struct { uint32_t *data; int64_t len; } screen_words;
typedef struct { const uint8_t *data; int64_t len; } screen_bytes;

static void *(*SDL_CreateWindow)(const char *, int, int, int, int, uint32_t);
static void *(*SDL_CreateRenderer)(void *, int, uint32_t);
static void *(*SDL_CreateTexture)(void *, uint32_t, int, int, int);
static int (*SDL_UpdateTexture)(void *, const void *, const void *, int);
static int (*SDL_RenderClear)(void *);
static int (*SDL_RenderCopy)(void *, void *, const void *, const void *);
static void (*SDL_RenderPresent)(void *);
static int (*SDL_PollEvent)(void *);
static int (*SDL_SetRelativeMouseMode)(int);
static void (*SDL_Quit)(void);

static void *renderer, *texture;
static int width, height, grabbed, ctrl_down;

// A USB keyboard usage (which is what SDL calls a scancode) as the PC's scan code; 0 for a
// key the PC keyboard has not.
static int scan_of(int usage) {
    static const uint8_t letters[26] = { 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26, 0x32,
                                         0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C };
    static const uint8_t row[17] = { 0x1C, 0x01, 0x0E, 0x0F, 0x39, 0x0C, 0x0D, 0x1A, 0x1B, 0x2B, 0x2B, 0x27, 0x28, 0x29, 0x33, 0x34, 0x35 };
    if (usage >= 4 && usage <= 29) return letters[usage - 4];
    if (usage >= 30 && usage <= 38) return usage - 30 + 0x02;
    if (usage == 39) return 0x0B;
    if (usage >= 40 && usage <= 56) return row[usage - 40];
    if (usage == 57) return 0x3A;
    if (usage >= 58 && usage <= 67) return usage - 58 + 0x3B;
    switch (usage) {
    case 68: return 0x57;
    case 69: return 0x58;
    case 73: return 0x152;
    case 74: return 0x147;
    case 75: return 0x149;
    case 76: return 0x153;
    case 77: return 0x14F;
    case 78: return 0x151;
    case 79: return 0x14D;
    case 80: return 0x14B;
    case 81: return 0x150;
    case 82: return 0x148;
    case 224: return 0x1D;
    case 225: return 0x2A;
    case 226: return 0x38;
    case 228: return 0x11D;
    case 229: return 0x36;
    case 230: return 0x138;
    }
    return 0;
}

// Opens a window for a frame buffer of w by h pixels. Returns 0, or -1 if SDL2 is not there
// or will not start.
int32_t screen_open(int32_t w, int32_t h) {
    static const char *names[] = { "/opt/homebrew/lib/libSDL2.dylib", "/usr/local/lib/libSDL2.dylib",
                                   "libSDL2.dylib", "libSDL2-2.0.so.0", 0 };
    void *lib = 0;
    for (int i = 0; names[i] && !lib; i++) lib = dlopen(names[i], RTLD_NOW);
    if (!lib) return -1;
    int (*SDL_Init)(uint32_t) = dlsym(lib, "SDL_Init");
    SDL_CreateWindow = dlsym(lib, "SDL_CreateWindow");
    SDL_CreateRenderer = dlsym(lib, "SDL_CreateRenderer");
    SDL_CreateTexture = dlsym(lib, "SDL_CreateTexture");
    SDL_UpdateTexture = dlsym(lib, "SDL_UpdateTexture");
    SDL_RenderClear = dlsym(lib, "SDL_RenderClear");
    SDL_RenderCopy = dlsym(lib, "SDL_RenderCopy");
    SDL_RenderPresent = dlsym(lib, "SDL_RenderPresent");
    SDL_PollEvent = dlsym(lib, "SDL_PollEvent");
    SDL_SetRelativeMouseMode = dlsym(lib, "SDL_SetRelativeMouseMode");
    SDL_Quit = dlsym(lib, "SDL_Quit");
    if (!SDL_Init || !SDL_CreateWindow || !SDL_CreateRenderer || !SDL_CreateTexture || !SDL_UpdateTexture || !SDL_RenderClear
        || !SDL_RenderCopy || !SDL_RenderPresent || !SDL_PollEvent || !SDL_SetRelativeMouseMode || !SDL_Quit) return -1;
    if (SDL_Init(0x20) != 0) return -1;                                  // SDL_INIT_VIDEO
    // Centred, shown, and a pixel of the guest's is a point of the host's (not a device pixel).
    void *window = SDL_CreateWindow("g86m  (a click takes the pointer; Ctrl+Alt gives it back)", 0x2FFF0000, 0x2FFF0000, w, h, 0x4);
    if (!window) return -1;
    renderer = SDL_CreateRenderer(window, -1, 0);
    if (!renderer) return -1;
    // A pixel is four bytes: nothing, red, green, blue. As one number that is BGRX8888.
    texture = SDL_CreateTexture(renderer, 0x16661804, 1, w, h);          // streaming
    if (!texture) return -1;
    width = w;
    height = h;
    return 0;
}

// Shows the frame buffer: width * height * 4 bytes.
void screen_show(screen_bytes pixels) {
    if (!texture || pixels.len < (int64_t)width * height * 4) return;
    SDL_UpdateTexture(texture, 0, pixels.data, width * 4);
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, 0, 0);
    SDL_RenderPresent(renderer);
}

// What happened at the window since the last call, into out. Returns how many.
int32_t screen_poll(screen_words out) {
    if (!texture) return 0;
    union { uint32_t type; uint8_t bytes[64]; } ev;
    int n = 0;
    static int buttons;
    while (n < out.len && SDL_PollEvent(&ev)) {
        if (ev.type == 0x100) {                                          // SDL_QUIT
            out.data[n++] = 4u << 24;
        } else if (ev.type == 0x300 || ev.type == 0x301) {               // a key down or up
            int32_t usage;
            memcpy(&usage, ev.bytes + 16, 4);
            int up = ev.type == 0x301;
            if (usage == 224 || usage == 228) ctrl_down = !up;
            if (grabbed && !up && ctrl_down && (usage == 226 || usage == 230)) {
                grabbed = 0;
                SDL_SetRelativeMouseMode(0);
            }
            int code = scan_of(usage);
            if (code) out.data[n++] = 1u << 24 | (uint32_t)code | (up ? 0x200u : 0);
        } else if (ev.type == 0x400) {                                   // the mouse moved
            int32_t dx, dy;
            memcpy(&dx, ev.bytes + 28, 4);
            memcpy(&dy, ev.bytes + 32, 4);
            if (!grabbed) continue;
            if (dx > 2047) dx = 2047;
            if (dx < -2047) dx = -2047;
            if (dy > 2047) dy = 2047;
            if (dy < -2047) dy = -2047;
            out.data[n++] = 2u << 24 | ((uint32_t)dx & 0xFFF) | ((uint32_t)dy & 0xFFF) << 12;
        } else if (ev.type == 0x401 || ev.type == 0x402) {               // a button down or up
            if (!grabbed) {
                // The click that takes the pointer is not the guest's.
                if (ev.type == 0x401) { grabbed = 1; SDL_SetRelativeMouseMode(1); }
                continue;
            }
            int bit = ev.bytes[16] == 1 ? 1 : ev.bytes[16] == 3 ? 2 : ev.bytes[16] == 2 ? 4 : 0;
            if (ev.type == 0x401) buttons |= bit; else buttons &= ~bit;
            out.data[n++] = 3u << 24 | (uint32_t)buttons;
        }
    }
    return n;
}

void screen_close(void) {
    if (texture) SDL_Quit();
    texture = 0;
}
