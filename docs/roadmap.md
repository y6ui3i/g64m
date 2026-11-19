# Roadmap

M5 left g86m with a 32-bit Linux kernel and a busybox shell on a serial console: no disk, no
network, no clock chip, no screen beyond 80x25 text. The stages after it go to a graphical
desktop that can browse the web, still as an i686, and only then to x86_64.

| Stage | Goal | Done when |
|---|---|---|
| M6 | A clock and a disk (done) | `date` in the guest shows the host's date; a root file system on an IDE disk is mounted and written |
| M7 | A network (done) | `wget https://...` from the serial console fetches a page through the host |
| M8 | A screen (done by script; the window by hand) | X (Xfbdev, twm, xterm) comes up in a window on the host, with keyboard and mouse |
| M9 | A browser (done) | NetSurf or Dillo shows a page fetched over HTTPS |
| M10 | x86_64 | A 64-bit Linux kernel boots to a shell |

## Why 32-bit first

**The oracle stays.** Every stage so far was checked against rustx86, line for line at every
instruction boundary. rustx86 has the devices M6 to M8 need: CMOS, IDE, NE2000, the Bochs VBE
interface (dispi), VGA, the 8042 with a mouse. It has no long mode. Going to x86_64 first would
leave g86m without its strongest test at the point where it needs one most.

**Each stage shows something.** A date, a fetched page, a window, a browsed site: each is a
milestone that can be seen and written about, and each is checked on its own.

**The devices carry over.** Once the 32-bit desktop works, x86_64 is a new CPU and SSE2 on top of
devices that already work. Doing it the other way would build the CPU against no oracle and the
devices on a CPU that is still moving.

## The stages

### M6: a clock and a disk

- **CMOS/RTC** (ports 70h and 71h), reading the host's time. HTTPS checks a certificate's dates,
  so M7 fails without it.
  Done (E074): the clock starts at the host's time in a terminal and at a fixed date in a
  scripted run, and runs on guest time.
- **IDE** (PIO first), backed by an image file. X and a browser do not fit well in an
  initramfs, and a disk that is written lets the guest keep what it was given.
- Oracle: rustx86's `cmos.rs` and `ide.rs`; Linux's own probing of both.
  Done (E075): an ATA disk on the primary channel, which Linux's `pata_legacy` drives; the
  root file system is ext2 on it. rustx86's `ide.rs` turned out to be an ATAPI CD-ROM, so
  the disk's commands are from the standard and the test is the kernel's driver.

### M7: a network

- **NE2000** on the ISA bus: the simplest card Linux still drives, and the one rustx86 has
  (`ne2000.rs`, `dp8390.rs`). PCI and virtio-net wait until there is a reason.
- **The host side** is the larger part. A user-mode network stack lets the guest reach the
  outside without root: [libslirp](https://gitlab.freedesktop.org/slirp/libslirp), the C library
  QEMU uses, linked the way `console.c` and `jit.c` are. It would be the project's third new
  technology (after Goose and the JIT), and its use is to be recorded in the README when it is
  taken. macOS's vmnet was not chosen: it needs root or an entitlement.
- Before the screen because it can be checked from the serial console, with a script, and
  needs no window.
- Done (E076, E077). Two things were not as written above. The kernel has no ISA NE2000
  driver, only `ne2k-pci`, so `--net` brings a PCI bus with it. And HTTPS stopped at SSE2,
  which the guest's OpenSSL is compiled for: MMX and SSE2 were brought forward from M10,
  and checked against rustx86 (306 cases).

### M8: a screen

- **Bochs VBE** (dispi) with a linear frame buffer, which Linux drives with `bochs-drm` or
  `vesafb`; the host draws it with **SDL2**, which the README already names as the library for a
  screen.
- **The 8042's second port** for a PS/2 mouse; the keyboard side is there already.
- The guest: Xfbdev (or Xorg's fbdev driver), twm and xterm, built for i686 with Buildroot.
- 128 MB of RAM (what g86m has now) is enough for this and for M9.
- M7 and M8 do not depend on each other; the order can be swapped if a window is wanted first.
- Where it stands (E078): X comes up and is typed into, by script. Not as written above:
  the kernel has neither `bochs-drm` nor `vesafb` built in, only `efifb`, so there is no
  Bochs VBE device; the loader declares a frame buffer in the boot parameters, as rustx86
  found. And the guest's X is Alpine's Xorg with icewm, from rustx86's X disk, not Xfbdev
  and twm from Buildroot. The window's keyboard and mouse are to be tried by hand.

### M9: a browser

- **NetSurf or Dillo.** Both run on i686 without SSE, on X or a frame buffer, and speak HTTPS.
  Sites that need much JavaScript are out of reach and not a goal.
- Done (E079): Dillo from the X disk, on `https://example.com/`. It "runs without SSE" was
  wrong for Alpine's build of everything around it; E077 had already brought SSE2.
- **Firefox and Chromium are not a goal.** Chromium dropped 32-bit Linux long ago and Firefox has
  ended it too; both need SSE2, and both need more memory and speed than an emulator gives.

### M10: x86_64

- **The name changes when this stage is done**, and not before: once a 64-bit Linux kernel
  boots to a shell, g86m is renamed **g64m**. The repository, the directory, the
  executable, `src/g86m.goose` and the messages are changed together, in one step. Decided
  2026-11-19.

- **SSE2** is required: the x86_64 ABI passes floats in XMM registers, so no 64-bit user space
  runs without it. This is likely the largest part. (Done for the i686 in E077, for M7; the
  64-bit forms and XMM8 to XMM15 are what is left of it here.)
- **Long mode**: REX prefixes and a 64-bit operand size through the ALU, RIP-relative
  addressing, four-level paging, EFER, STAR/LSTAR, FS/GS base and SWAPGS, SYSCALL/SYSRET, the
  64-bit IDT and TSS.
- **128-bit products and quotients** (`MUL`, `IMUL`, `DIV` on 64-bit operands): Goose has no
  128-bit integer, so they are done in 32-bit halves or in a few lines of C.
- **A new oracle**, since rustx86 has no long mode:
  - user-mode instructions, against real hardware: single-step a static ELF under ptrace on an
    x86_64 Linux host and compare the registers after each instruction, as test386 was compared
    with real hardware;
  - system instructions (entering long mode, paging), against QEMU's TCG stepping one
    instruction at a time.
- Steps: 64-bit user-mode instructions and SSE2 first, run as a user-mode emulator of static ELF
  binaries against the ptrace oracle; then long mode and paging against QEMU; then the kernel.
- **The 64-bit CPU is new code in files of its own** (`src/cpu64.goose`, with `src/x64.goose`
  as a second root file beside `src/g86m.goose`), not long mode added to the 32-bit CPU: a
  64-bit kernel can be entered at its 64-bit entry point with paging already on, as the 32-bit
  one is entered at its 32-bit entry point now, so nothing below long mode has to run in it.
  The devices are what the two will share.
- Done so far:
  - E091: the integer instructions in user mode, and the ptrace oracle
    (`tools/oracle/step64.c`, `tools/difftest64.sh`).
