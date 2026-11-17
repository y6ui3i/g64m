# Experiment ledger

A card is written before an experiment runs, and its result is added in the same place.

## E001: Can the core of an emulator be written in Goose? (M0, 2026-11-12)

- **Hypothesis**: With Goose v2026.4, the four shapes at the core of an x86 interpreter can be written
  without fighting the language.
  (a) A struct for the CPU state and 1 MB of guest RAM, both as globals
  (b) Opcode dispatch with `match`, at a usable speed
  (c) A round trip of the CPU state through `to_bytes` / `from_bytes` (the seed of snapshots)
  (d) Calling our own C through `extern fn` (glue for things like terminal raw mode)
- **What changed since last time**: First run. The inputs are rustx86's `asm/hello.bin` and
  `asm/bench.bin` (a 10-instruction loop with a fixed instruction count).
- **Next move for each result**:
  - hello prints `Hello, World!`, bench stops at HLT and runs at 100 MIPS or more → go on to M1
    (the full 8086 instruction set) written the same way
  - It works but below 30 MIPS → read the generated C, then change the bounds checks (`--bce-lines`)
    and where RAM lives, and measure again
  - (a) or (b) cannot be written under the language rules → move RAM to the C side and reassess.
    If that fails too, report it as grounds for dropping Goose
  - Only (c) or (d) cannot be written → carry on with M1, and record in an ADR that snapshots and
    glue live on the C side
- **Cut-off**: The same day. On anything that looks like a compiler bug, keep a minimal reproduction
  and move on with a workaround.

### Result

2026-11-12, Goose v2026.4 (macos-arm64 release), clang 21.0.0, Apple Silicon. All four passed.
**Next move: on to M1, written the same way.**

| Item | Result |
|---|---|
| (a) struct + 1 MB RAM | `var ram: u8[RAM_SIZE]` and `var cpu: Cpu` work as globals (`probe/m0.goose`) |
| (b) `match` dispatch | hello.bin prints `Hello, World!` and halts after 84 instructions. bench.bin halts after 369,095,178 instructions; three runs took 1857–1890 ms = **about 197 MIPS** |
| (b) correctness | At the end of bench, AX=57136 BX=13090 DX=4148 and the instruction count match a separately written Python model |
| (c) snapshot | `Cpu[>..]` (30 bytes) and 1 MB of RAM make the round trip through `to_bytes` → `from_bytes` and compare equal. Corrupting the first byte returns `false` and an empty array (`probe/m0_snap.goose`) |
| (d) C interop | `c_sources` in `m0_cext.build` links our own C; a scalar and a slice (`{data, len}`) cross the boundary (`probe/m0_cext.goose`) |

What was learned:

- A `--debug` build takes 21,248 ms on bench (about 17 MIPS). It adds signed-overflow and range
  checks, so tests use debug and measurements use release
- Serialization works on arrays. A single struct goes in a one-element `T[>..]`
- `args` and `write_stderr` need `import os;` (`std` alone does not provide them)
- An integer `match` takes half-open ranges (`0x40..0x48`), so opcodes with an embedded register
  number can be listed as they are
- The only thing typechecking made me fix was one import line. Nothing got stuck on the language rules

Not measured: ModR/M with memory operands, interrupts, devices. The 197 MIPS figure is for a
10-instruction loop, not for running an operating system.

## E002: Speed against the same fragment written in Rust (2026-11-12)

- **Hypothesis**: Rust code of the same shape as `probe/m0.goose` (`probe/m0.rs`: the same
  instructions, the same flag computation, the same 1 MB of RAM) is within ±20% of the Goose version
  on bench.bin.
- **What changed since last time**: The Goose version from E001 is unchanged. Two things are added
  to compare against: (1) the same fragment in Rust, and (2) rustx86's own `core/examples/bench.rs`,
  as a reference only, since it is the finished product with a decode cache, devices and interrupts.
- **Next move for each result**:
  - Within ±20% → stop worrying about the language's speed and go on to M1. Work on speed waits
    until the instruction set is complete
  - Goose is more than 20% slower → before M1, look at the remaining bounds checks with
    `--bce-lines` and decide how RAM access is written
  - Goose is more than 20% faster → check why once (the generated C and assembly), record it, and
    go on to M1
- **Cut-off**: The same day. Five runs each, compared by the median.

### Result

2026-11-12, Apple Silicon, bench.bin (369,095,178 instructions), median of five runs each.
**The hypothesis was wrong. The Goose version takes about 35% longer than Rust code of the same shape.**

| Implementation | Median | MIPS | Notes |
|---|---:|---:|---|
| Rust fragment (`probe/m0.rs`, rustc 1.97.1 `-C opt-level=3`) | 1386 ms | about 266 | |
| Goose fragment (`probe/m0.goose`, v2026.4 → clang 21 `-O2`) | 1873 ms | about 197 | 1.35 times the Rust time |
| rustx86 itself (`core/examples/bench.rs`, release) | 7.07 s | about 52 | The finished product, with devices, interrupts and 32-bit support; a reference only |

All three execute 369,095,178 instructions. The two fragments also agree on AX / BX / DX at the end.

The cause was looked into once:

- **Not bounds checks.** `--bce-lines` shows 59 of 60 removed. The one that remains is on the AH side
  of `get8` (`regs[i - 4]`), which bench's inner loop never reaches
- **Not indirection through globals.** `GS_GL` in the generated C is the address of static storage;
  no pointer is reloaded
- **Hardly the C optimization level.** Recompiling the generated C at `-O3` gives 1765 ms (about 5% better)
- One candidate remains and is untested: a `u8` write to RAM may alias the CPU state, so clang may
  reload flags and registers after every write. Rust avoids this through the uniqueness of `Box`

Next move (the "more than 20% slower" branch of the card, updated with what was found):

- Bounds checks are not the cause, so the way RAM access is written stays. **M1 goes ahead as planned**
- Speed is measured again once the instruction set is complete, at the point lazy flags go in
  (keep only the result and the operands, compute a flag when it is read). That cuts the reads and
  writes in set_flag, so it should help at the same time if aliasing reloads are the cause
- Even as a fragment, Goose is about 3.8 times faster than rustx86 itself. rustx86 does much more,
  so this does not mean Goose is faster than Rust

## E003: Verify the 8086 instruction set by diffing traces against rustx86 (M1, 2026-11-12)

- **Hypothesis**: The 16-bit real-mode implementation in `src/` matches rustx86 on every line of the
  state at each instruction boundary (CS:IP, the eight general registers, ES/SS/DS, FLAGS), for eight
  test boot sectors, one per instruction group (`tests/asm/t_*.asm`), and four rustx86 boot sectors.
- **What changed since last time**: The fragment from E001 (25 instructions) grew into the 8086 + 186
  instruction set. The oracle is `trace16`, added to rustx86 (`tools/oracle/trace16.rs`). rustx86
  matches expected values from a real 386 bit for bit on test386.asm, so g86m follows rustx86 on
  undefined flags too.
- **Next move for each result**:
  - Every line matches → fix the expected traces in `tests/expected/`, open a PR, go on to M2 (ELKS)
  - A mismatch → find the instruction at the first line that differs and fix it. If it is an
    undefined flag, read rustx86's implementation and follow it
  - If rustx86 looks like it departs from the 8086 specification → do not follow it; record it and ask
- **Cut-off**: The same day. Instructions with no test (IN/OUT on real devices, the interrupt
  controller) move to M2.

### Result

2026-11-12. **Every line matched. Next move: fix the expected traces, open a PR, go on to M2.**

| Test | Lines | Contents |
|---|---:|---|
| t_alu / t_alu2 | 945 / 400 | The 8 operations and TEST, INC / DEC / NEG / NOT, in every operand form |
| t_shift | 2924 | 7 rotates and shifts × 14 counts × 8 and 16 bits |
| t_muldiv | 650 | MUL / IMUL / DIV / IDIV, divide errors, CBW / CWD / AAM / AAD |
| t_bcd | 4533 | DAA / DAS / AAA / AAS × 52 values of AL × 4 combinations of CF and AF |
| t_string | 96 | MOVS / CMPS / SCAS / STOS / LODS, each REP form, both directions of DF, segment overrides |
| t_flow | 538 | 16 conditions × 14 flag words, the LOOP family, CALL / RET / far forms, INT / INTO / IRET |
| t_misc | 147 | 24 ModR/M forms, default and overridden segments, the stack, PUSHA / ENTER, XCHG / XLAT, flag instructions |
| hello / interrupt / vram | 98 / 37 / 44 | rustx86's boot sectors |
| s_selfcheck | - | Self-check for the two cases the oracle cannot judge (IDIV of the minimum value, SALC) |

Of the four rustx86 boot sectors the hypothesis named, three were compared. The fourth, `mode13.bin`,
needs devices and is listed under "Left out of M1" below.

Debug and release builds give the same result. `tools/difftest.sh` reproduces it; the expected traces
are fixed in `tests/expected/`, so rustx86 is not needed.

On the first run, 7 of the 11 matched. The causes of the other 4:

| Mismatch | Cause | Fixed in |
|---|---|---|
| OF after right rotates and shifts | A real 386 leaves OF alone unless the count is 1 (only left rotates update it at every count). g86m updated it every time | g86m |
| The top 4 bits pushed by PUSHF | rustx86 defaults to its 8086 profile, which pushes them as ones. g86m pushed zeros | g86m |
| The high word of 16-bit `MUL` was 0 | A Goose compiler bug ([goose-notes.md](goose-notes.md), item 1) | g86m (workaround) |
| The sign of the IDIV remainder | Goose's `%` floors ([goose-notes.md](goose-notes.md), item 2) | g86m |

The tests had three bugs of their own: NASM emitted the 386 near Jcc; a table was read with DF set,
so the read ran backwards; and a caller of RET n did not push the arguments. The backwards read was
an endless loop, and a trace with no cut-off grew to 60 GB. It was deleted at once, and `difftest.sh`
now stops at 2 million instructions.

What turned up in rustx86 and was not followed is at the end of [goose-notes.md](goose-notes.md).

Speed: bench.bin takes 3394–3487 ms on the release build = **about 108 MIPS**. It is slower than the
E001 fragment (197 MIPS) because prefix handling and the general form of ModR/M are now in. It is
about twice rustx86 itself (about 52 MIPS).

Left out of M1:

- `mode13.bin`: it needs the INT 10h mode set and the VGA DAC ports. Devices start in M2
- IN / OUT on real devices, the PIC and PIT, hardware interrupts
- The 66h / 67h prefixes and instructions that start with 0Fh (386 and later). g86m stops on them
- Checking what is in VRAM. For vram.bin only the register trace is compared

## E004: Boot ELKS to a shell (M2, 2026-11-12)

- **Hypothesis**: With a PIC, a PIT, an 8042 keyboard controller, BIOS disk services (INT 13h) and
  hardware interrupt delivery added to the M1 core, ELKS 0.9.1 (`fd2880.img`, the image rustx86
  boots) reaches `login:`, accepts `root` typed through the keyboard controller, and runs a command
  at the shell prompt.
- **What changed since last time**: M1 ran boot sectors with interrupts disabled and no devices. This
  adds devices, a virtual clock (the PIT advances one tick per 4 instructions), interrupt delivery
  between instructions, and a headless script (`--wait TEXT` / `--type TEXT`) that drives the
  keyboard and reads the text screen at B8000h.
- **Next move for each result**:
  - Reaches the shell and `uname -a` prints an ELKS line → fix the script as a regression test,
    open a PR, then add an interactive terminal front end
  - Stops on an unimplemented BIOS call, port or opcode → implement it and run again (the machine
    stops rather than guessing, so each stop names what is missing)
  - Runs without stopping but never reaches `login:` → compare the trace with rustx86's from the
    start of the disk boot, find the first line that differs that is not an interrupt arriving at a
    different time, and fix that instruction
  - The screen and rustx86's agree up to a point and then the kernel hangs waiting → suspect the
    clock or the interrupt controller, not the CPU: check that IRQ0 is delivered and acknowledged
- **Cut-off**: The same day. If the kernel boots but the keyboard path does not work by then, record
  how far it got and open the PR with `login:` as the reached point.

### Result

2026-11-12. **ELKS reaches the shell and runs commands. Next move: open a PR, then an interactive
terminal front end.**

The script waits for `login:`, types `root`, waits for the `# ` prompt, runs `uname -a` and then
`ls /bin | head -3; echo done-$?`. The screen at the end:

```
[0.69 secs] login: root
# uname -a
ELKS elks 0.9.1 commit d9ca2128 05 May 2026 15:34:43 -0700 ibmpc i8086
# ls /bin | head -3; echo done-$?
advent
arp
banner
done-0
#
```

- It passes on both the debug and the release build, and is now part of `tools/difftest.sh`
  (skipped, and reported as skipped, when `images/fd2880.img` is absent)
- The whole script takes about 0.1 s of real time on the release build
- The M1 trace tests still match on every line after the device work
- bench.bin: 3468–3577 ms, about 105 MIPS (about 108 before). The per-instruction timer countdown
  and the interrupt check cost about 3%

ELKS reached `login:` on the first run of the new code: the machine did not stop on an unimplemented
BIOS call, port or opcode. So the "implement what it stops on" branch of the card was never taken,
and the trace comparison against rustx86 for the disk boot was not needed and not done.

What that leaves untested, since ELKS did not exercise it or nothing checks it:

- The BIOS keyboard path (INT 16h, the INT 09h handler). ELKS installs its own keyboard handler
- INT 10h scrolling and character writes other than teletype output
- Disk writes (INT 13h AH=03h) reach the in-memory image only; nothing is written back to the file
- The clock. One timer tick per 4 instructions is a made-up ratio, and idle time is skipped, so
  nothing here says whether time passes at a believable rate for a person at the keyboard

Known wrong:

- The date ELKS prints is `Thu Oct 17 09:47:13 1991`. There is no CMOS clock, so ports 70h/71h read
  as FFh and ELKS decodes that
- `ktcp` fails to open `/dev/ne0`: the image has networking enabled and there is no NE2000. Expected

Ports ELKS used that nothing answers (from `--ports`): 70h/71h (CMOS), 80h (POST delay), 2E9h/2F9h/
3E9h/3F9h (serial probes), 240h–24Fh and 300h–31Ch and 330h (network and ATA probes), 3F2h (floppy
controller), 110h, 510h/511h.

Not done in M2: an interactive front end. The only way to use the shell so far is the script.

## E005: An interactive terminal console (2026-11-12)

- **Hypothesis**: A console that draws the 80x25 text screen in the host terminal with ANSI escapes,
  feeds host keystrokes to the keyboard controller as scancodes, and paces the virtual clock against
  real time, is enough to use the ELKS shell by hand: what is typed appears, commands run, and
  `sleep 3` takes about 3 seconds.
- **What changed since last time**: E004 drove the machine with a script and skipped idle time. This
  adds C glue for raw terminal mode (`src/console.c`), a renderer that sends only the cells that
  changed, key translation (printable keys, Enter, Backspace, Ctrl combinations, arrows and the
  editing keys), and pacing: the machine runs one hundredth of a second of virtual time, then sleeps
  until real time catches up. The virtual CPU speed stays at 4 instructions per timer tick, about
  4.77 million instructions per second.
- **Next move for each result**:
  - A pseudo-terminal test logs in, runs a command, sees `sleep 3` take 2.5–3.5 s, and quits with
    the terminal restored → open a PR and hand it over to be tried by hand
  - Text is garbled or keys are lost → dump the bytes the console writes and reads in the test and
    fix the renderer or the key translation
  - `sleep 3` is far from 3 s → the pacing or the timer model is wrong; measure virtual against
    real time over the same interval before changing the ratio
  - The terminal is left in raw mode after quitting or a crash → fix the restore path before
    anything else, since that breaks the user's shell
- **Cut-off**: The same day. FreeDOS is out of scope here: it needs M3.

### Result

2026-11-12. **The console works through a pseudo-terminal. Next move: open a PR and hand it over to
be tried by hand.**

`tools/console_test.py` starts g86m on a pseudo-terminal, keeps its own 80x25 grid from the escape
sequences g86m writes, and types as a person would:

| Check | Result |
|---|---|
| Boots to `login:` | 0.7 s of real time, the same figure ELKS prints as `[0.69 secs]` |
| Logs in as root, runs `uname -a` | `ibmpc i8086` on the screen, then the prompt |
| `sleep 3; echo slept` | 3.04 s of real time (accepted range 2.5–3.5 s) |
| Backspace | Seven Backspaces erase `wrongXX`, and the line that runs prints `backsp` |
| Ctrl-C | `sleep 30` is still running after 1 s; Ctrl-C brings the prompt back in 0.02 s |
| Ctrl-] | g86m exits with status 0, leaves the alternate screen, and the terminal modes are back to what they were |

It is part of `tools/difftest.sh` when the image and python3 are there. The M1 trace tests and the
ELKS script still pass on both builds. bench.bin is unchanged at about 105 MIPS.

Two things went wrong on the way, both in the test and not in the console:

- The first version stripped escape sequences and searched the remaining text. The console sends
  only the cells that changed, so blanks that were already on the screen are never sent, and `# `
  could not match. The test now applies cursor moves to a grid of its own
- The first Ctrl-C check passed in 0.00 s: it looked at the grid before reading any new output and
  saw the old prompt. It now waits until `sleep 30` has been running for a second before sending
  Ctrl-C

Not checked, because a pseudo-terminal test cannot see it:

- How it looks: colours, the cursor, the code page 437 line-drawing characters. ELKS at a shell
  prompt uses none of the last
- A host terminal smaller than 80x25. Nothing handles it; lines will wrap (this was the first
  thing to go wrong by hand; see the follow-up below)
- Arrow keys, function keys and the editing keys. The translation is written but no test presses them
- How it feels to type. The guest runs at about 4.77 million instructions per second, a made-up
  figure that follows from 4 instructions per timer tick

### Follow-up: first try by hand (2026-11-12)

The first session by hand looked broken: prompts repeated down the screen, and the output of `ls`
appeared as one line with a `#` written over its start. The pasted screen had 10 lines.

- **Cause, as far as the evidence goes**: the terminal was shorter than 25 rows. The console
  addressed rows up to 25, a terminal clamps a row past its last line to the last line, and so the
  lower rows of the guest's screen were all drawn on top of each other there. This is the case the
  result above listed as not handled. It is inferred from the 10-line paste and from the fix
  curing a 10-row pseudo-terminal; the terminal's size at the time was not measured
- **Fix**: the console reads the terminal's size on every redraw and draws only the part of the
  80x25 screen that fits. Down the screen the view follows the guest's cursor and otherwise stays
  put; sideways it returns to column 0 whenever the cursor fits. A change of size or view clears
  and redraws
- **Test**: `tools/console_test.py` now also scrolls the guest's screen with `ls /bin`, fails if
  the console ever addresses a cell outside the terminal, and repeats the session on an 80x10 and
  a 60x12 terminal. All three sizes pass

The 60x12 run failed once before it passed: after a line longer than the view, the view stayed
shifted right and hid the `# ` prompt. That is why the sideways rule differs from the vertical one.

Still not checked on a real terminal: colours, the cursor, line-drawing characters, arrow and
function keys, and resizing the window while it runs.

### Follow-up: no way out (2026-11-12)

The second try by hand ended with "I don't know how to get out". The quit key, Ctrl-], was
mentioned in the README and nowhere on the screen.

- The way out is now shown in three places: a line printed before the console opens (held for 1.2 s
  when the terminal has no spare row, and left in the scrollback), the window title, and a dim line
  below the screen when the terminal has more than 25 rows
- Two more keys leave the console: F12 and Ctrl-\. Ctrl-] is awkward on some keyboard layouts
- The test checks the line before the console opens, the line below the screen at 100x30, and
  leaves by a different key in each of its three sessions

Adding the line below the screen turned up a bug in the previous follow-up: the first redraw did
not clear and set up the terminal unless the view differed from the default, so on a terminal of
25 rows or more nothing was cleared at the start. The first redraw now always does.

Whether Ctrl-] itself failed to reach g86m in that terminal, or was simply not known, is not
established.

## E006: Boot FreeDOS to a prompt (M3, 2026-11-12)

- **Hypothesis**: With the BIOS keyboard path completed (the INT 09h handler tracking Shift, Ctrl
  and Alt and filling the BIOS queue; INT 16h waiting idle for a key), FreeDOS 1.4
  (`fd14boot.img`, the image rustx86 boots) reaches its boot menu, starts FreeCOM, and runs `ver`
  and `dir` at the `A:\>` prompt. Unlike ELKS, FreeDOS does its screen, keyboard and disk work
  through the BIOS, so this exercises the paths E004 listed as untested.
- **What changed since last time**: The BIOS keyboard handler only handled unshifted keys and INT 16h
  spun in a loop while waiting. The script gains `\kNN` to press a key by scancode (F5 is `\k3F`).
- **Next move for each result**:
  - Reaches `A:\>` and `ver` prints a FreeDOS version → fix the script as a regression test, open
    a PR
  - Stops on an unimplemented BIOS call, port or opcode → implement it and run again
  - Stops on a 386 instruction → find out why FreeDOS thinks this is a 386 (the CPU detection
    reads the top bits of FLAGS and tries PUSH SP), fix the detection result, not the instruction
  - Hangs with no stop → compare the trace with rustx86's from the start of the disk boot
- **Cut-off**: The same day. The FreeDOS installer (which rustx86 reaches through 32-bit
  instructions) is out of scope: it needs M4.

### Result

2026-11-12. **FreeDOS reaches `A:\>` and runs commands. Next move: open a PR.**

The session presses F5 when the kernel banner appears, answers `\FREEDOS\BIN\COMMAND.COM` when
the kernel asks for the shell, and runs three commands. The screen at the end:

```
 Enter the full shell command line: \FREEDOS\BIN\COMMAND.COM
FreeCom version 0.86 - WATCOMC - XMS_Swap [Dec 30 2024 22:10:51]
A:\>ver /r
FreeCom version 0.86 - WATCOMC - XMS_Swap [Dec 30 2024 22:10:51]
DOS version 7.10
FreeDOS kernel 2043 (build 2043 OEM:0xfd) [compiled May 13 2021]
A:\>dir /w
 Volume in drive A is FD14-BOOT
 Volume Serial Number is BB79-CEB9
 Directory of A:\
KERNEL.SYS     FDAUTO.BAT     FDCONFIG.SYS   [FREEDOS]      SETUP.BAT
         4 file(s)         87,913 bytes
         1 dir(s)         807,936 bytes free
A:\>echo Done-%COMSPEC%
Done-A:\FREEDOS\BIN\COMMAND.COM
```

- It passes on the debug and release builds as a script, and through the console on a
  pseudo-terminal, where F5 is sent as the escape sequence a terminal sends for it. Both are in
  `tools/difftest.sh`, which now has 21 checks
- The M1 traces, the ELKS script and the ELKS console sessions still pass
- bench.bin: 3526–3795 ms, about 100–105 MIPS. Not distinguishable from before on three runs

As with ELKS, the kernel came up on the first run: the boot menu appeared without the machine
stopping on anything unimplemented. Two things did have to be fixed, both about keys arriving
faster than the guest takes them:

| Symptom | Cause | Fix |
|---|---|---|
| The shell path stopped at `\FREEDOS\BIN\CO` in the script | The script queued every key at once. FreeDOS reads keys through the BIOS, whose queue holds 15 | The script types one key per poll, and only once the guest has taken the last one |
| The same in the console when the path arrived in one write, as a paste does | The console passed everything it read straight on | The console keeps what it read and hands it over one key at a time |

The console change makes typing slightly slower to arrive: `sleep 3` measured from the moment the
line is written now takes 3.25 s instead of 3.04 s, because its 21 characters go in at one per
hundredth of a second.

What happens without F5, for the record:

- Enter at the language menu starts FreeCOM, which runs `FDAUTO.BAT`. That stops g86m at
  `unimplemented opcode 66 at 22c8:0759`: a 386 operand-size prefix. rustx86 gets past this point
  through its 32-bit instructions. Whether that program checks the CPU first was not looked into;
  the card's "why does FreeDOS think this is a 386" question is still open, and belongs with M4
- The menu screen shows `Singlestepping (F8) is:` with nothing after it. Not looked into

Not tested: any DOS program other than the shell's built-in commands. `dir`, `ver` and `echo` are
all inside FreeCOM.

## E007: FreeDOS without F5 (2026-11-12)

First try by hand: "FreeDOS goes down at once". Without F5 the normal startup stops g86m, and in
the console the reason is printed while the alternate screen is up, so it is never seen.

The stop is at `66 53 66 9C 66 9C 66 58 66 0D ...`: PUSH EBX, PUSHFD, PUSHFD, POP EAX, OR EAX — the
usual test for CPUID. A program only runs that after deciding the CPU is at least a 386.

- **Hypothesis**: g86m answers the two standard CPU tests inconsistently. FLAGS bits 12–15 read as
  ones, which is an 8086; but PUSH SP pushes the value from before the decrement, which is a 286 or
  later. A program that tests PUSH SP first and then finds bits 12–14 stuck at one concludes "386".
  If PUSH SP pushes the decremented value, as a real 8086 does, the program takes its 8086 path and
  FreeDOS's normal startup gets past this point.
- **What changed since last time**: E006 always pressed F5. This runs the normal startup, with PUSH
  SP changed to the 8086 behaviour. M1 followed rustx86 here (rustx86 has the same mix but
  survives because it implements the 386 instructions).
- **Next move for each result**:
  - The startup gets past the stop and reaches a prompt or the installer's first question → keep
    the 8086 PUSH SP until M4 makes the machine a real 386, move the PUSH SP case from the trace
    test to the self-check, and test the normal startup
  - It still stops on a 386 instruction → the program does not test the CPU, or tests it another
    way. Read the code before the stop to see which, and record it; the real fix is then M4
  - It stops on something else → fix that if it is small, record it if not
- **Whatever the result**: the console must show why the machine stopped after it closes.
- **Cut-off**: The same day.

### Result

2026-11-12. **The hypothesis held. FreeDOS's normal startup now reaches `A:\>` without F5.**

With PUSH SP pushing the decremented value, the program that stopped g86m takes its 8086 path:

```
Welcome to the FreeDOS 1.4 installation program.
...
Do you want to proceed [Y,N]?N
The installation of FreeDOS 1.4 has been aborted.
A:\>dir /w
 Volume in drive A is FD14-BOOT
 Volume Serial Number is BB79-CEB9
 Directory of A:\
[FREEDOS]      FDAUTO.BAT     FDCONFIG.SYS   KERNEL.SYS     SETUP.BAT
         4 file(s)         87,913 bytes
         1 dir(s)         807,936 bytes free
```

- The session is: Enter at the language menu, `n` and Enter at the installer's question, then
  `dir /w`. It is in `tools/difftest.sh` on both builds, next to the F5 session; 23 checks, all pass
- This is the first DOS program other than the shell to run: the installer front end draws its
  banner and prompt through INT 10h AH=02h/08h/09h (about 3,500, 1,000 and 1,100 calls)
- PUSH SP left the trace test (`t_misc`), because g86m no longer agrees with rustx86 there, and went
  into the self-check, which now expects the 8086 result. The other ten expected traces were
  regenerated from the oracle and came out byte for byte the same
- The console now repeats the reason the machine stopped after it closes. Nothing tests that

One wrong turn on the way: after `n` the installer seemed to hang. It was waiting for Enter. Finding
that out took a memory dump of the text screen (`--dump`, new), which showed the screen was drawn
correctly and the cursor sat right after the `N`. The stop message now also includes the bytes at
the stopping address, and `--ports` reports how often each BIOS service was called.

What this does not settle:

- Whether "goes down at once" by hand was this stop. It fits (Enter at the menu, then a stop within
  a second of guest time), but the session that failed was not captured
- PUSH SP is now the 8086 behaviour on purpose. M4 has to turn it back when the machine becomes a
  386, together with the FLAGS bits, or the same inconsistency returns the other way round
- The installer was declined. Going on with `y` was not tried

## E008: Make the machine a 386 in real mode (M4a, 2026-11-13)

M4 is split in three: (a) the 386 instruction set in real mode, (b) protected mode, (c) paging and
test386. This card is (a).

- **Hypothesis**: With 32-bit registers, the 66h/67h prefixes, 32-bit addressing with SIB bytes, FS
  and GS, and the 0Fh instructions, g86m matches rustx86's 32-bit profile line for line on the full
  32-bit state (EIP, the eight 32-bit registers, six segment registers, EFLAGS) for the existing
  eight 16-bit test programs and for new 32-bit ones. ELKS and FreeDOS still boot, and FreeDOS's
  normal startup, which now sees a 386 and takes its 32-bit path, still reaches the installer.
- **What changed since last time**: Until now g86m was an 8086 to software that asked (E007). It
  becomes a 386 without an FPU and without CPUID: FLAGS bits 12–14 are writable, PUSH SP pushes
  the value from before the decrement, and the 386 instructions exist. The oracle changes with it,
  from rustx86's default 8086 profile to its 32-bit profile, and the trace gains the upper halves
  of the registers. The expected traces are all regenerated.
- **Next move for each result**:
  - Every trace matches and both systems boot → open a PR, go on to protected mode (M4b)
  - A trace differs → fix the first line that differs. rustx86's 32-bit profile has an FPU and
    CPUID and g86m does not, so a difference in FPU instructions, CPUID, or the AC and ID bits of
    EFLAGS is expected: keep those out of the trace tests rather than following the oracle
  - FreeDOS stops on an instruction → implement it if it is a 386 instruction; if it is a 486 or
    later one, find out which CPU test said so
  - ELKS or FreeDOS behaves differently as a 386 without stopping → compare the screen with the
    8086 run and record what changed
- **Cut-off**: The same day for the instruction set. Entering protected mode stops the machine with
  a message; that is M4b.

### Result

2026-11-13. **Every trace matches and both systems boot. Next move: open a PR, then protected mode (M4b).**

`tools/difftest.sh` has 31 checks and all pass on the debug and release builds.

| Test | Lines | Contents |
|---|---:|---|
| The eleven 16-bit traces from M1 | as before | Regenerated on the 32-bit oracle; they matched on the first run, before any 32-bit test existed |
| u_alu | 590 | The 8 operations and TEST on 32-bit registers, memory and immediates; INC / DEC / NEG / NOT |
| u_shift | 1393 | 32-bit rotates and shifts; SHLD / SHRD at 16 and 32 bits × 11 counts |
| u_muldiv | 328 | 32-bit MUL / IMUL / DIV / IDIV with divide errors; two- and three-operand IMUL; CWDE / CDQ |
| u_addr | 75 | Every ModR/M and SIB shape through LEA; default segments of the 32-bit forms |
| u_misc | 365 | MOVZX / MOVSX, 16 SETcc × 10 flag words, near Jcc, BT / BTS / BTR / BTC, BSF / BSR, FS / GS, LSS / LFS / LGS |
| u_stack | 114 | PUSHAD / POPAD, PUSHFD / POPFD, 32-bit ENTER / LEAVE, string instructions with either size prefix, LOOP / JECXZ by address size, 32-bit CALL / RET, XLAT, SMSW, SIDT |
| s_386 | - | Self-check for three cases where g86m follows the Intel manual and rustx86 does not |

ELKS and FreeDOS need no change to their scripts: the ELKS shell session, FreeDOS's normal startup,
the F5 path and all four console sessions pass as before. FreeDOS's normal startup now runs the code
that stopped g86m in E007 (PUSHFD and friends) instead of avoiding it.

Of the six new tests, three matched on the first run (u_alu, u_addr, u_muldiv). The other three:

| Mismatch | Cause | Fixed in |
|---|---|---|
| OF after SHLD / SHRD | A real 386 leaves OF alone; g86m set it on a count of 1 | g86m |
| EBP after a 32-bit ENTER | With a 16-bit stack the frame pointer is BP: only the low half of EBP is written | g86m |
| CR0 read by SMSW | g86m started CR0 with the ET bit set; with no coprocessor it is clear | g86m |

The tests had one bug: `o32 call label` in NASM adds the prefix but keeps a 16-bit displacement, so
the call went into data. `call dword label` is the form that works.

Where g86m and rustx86 disagree and g86m was not changed (all three are in `s_386` instead of a
trace, and listed in [goose-notes.md](goose-notes.md)):

- BT-family instructions with an immediate bit offset above the operand size, on memory
- BT-family instructions with a negative 16-bit register bit offset
- IRETD in real mode

Speed: bench.bin takes 4613–4764 ms on the release build = **about 78 MIPS**, down from about 105.
Every instruction now resets and tests the operand and address sizes, and register and memory
access go through a width that can be 8, 16 or 32.

What was not done:

- **The screens were not compared.** The card said to compare ELKS's and FreeDOS's screens as a 386
  against the 8086 run. Only the scripted waits were checked; they pass, but a message that changed
  would not be noticed
- **No CPUID and no FPU.** rustx86's 32-bit profile has both; g86m answers as a 386
  without them, so instructions that touch them are kept out of the traces
- **Real mode is not checked for limits.** Offsets above FFFFh and a 32-bit EIP do not fault
- **Protected mode stops the machine.** Setting CR0.PE by MOV CR0 or LMSW prints a message and
  stops. LGDT and LIDT only store their operand
- **Instructions in the two-byte range that no test reaches**: MOV to and from debug registers, CLTS,
  INS / OUTS

## E009: Run test386 (M4b, 2026-11-13)

test386.asm is a ROM that replaces the BIOS, tests a 386 instruction by instruction, reports
progress as codes on a diagnostic port, and halts at the first failure. Its last stage prints
44,926 lines of results, to be compared with a reference taken from real hardware.

Reading its README changed the plan: it enters protected mode with paging already on (code 08h),
and goes on to ring 3, virtual-8086 mode, page faults and task switches. So "protected mode" and
"paging" cannot be separate steps for this test; M4b and M4c are one piece of work, measured by how
far the codes get.

- **Hypothesis**: (1) With a ROM boot mode and the diagnostic and serial ports, the real-mode stages
  (codes 00h–06h) pass on the M4a build as it is. (2) With protected mode, paging, faults with error
  codes, privilege changes, virtual-8086 mode and task switching added, the ROM reaches code FFh and
  its serial output matches the reference on every line.
- **What changed since last time**: M4a stopped the machine when CR0.PE was set. The ROM is built
  from barotto/test386.asm at commit cfd052d with `COM_PORT equ 1`, as rustx86's fetch script
  does. It is not in the repository (GPL-3.0).
- **Next move for each result**:
  - A real-mode stage fails → that is an M4a bug the traces did not catch. Find the instruction
    from the listing file and the last trace lines, fix it, add the case to a trace test
  - Stops at 08h on "protected mode is not implemented" → the expected starting point. Implement
    in the order the ROM needs: descriptor loading and CR0.PE, then paging, then interrupts through
    the IDT, then privilege changes, then virtual-8086 mode
  - Halts at a later code → read that stage's source, compare the trace with rustx86's from the
    same ROM, fix the first difference
  - Reaches FFh but the output differs from the reference → fix by the first differing line; the
    reference masks undefined flags, so every difference is a real one
- **Cut-off**: Each code reached is recorded. If the day ends before FFh, the PR says which code
  it stops at and why.

### Result

2026-11-13. **Both halves of the hypothesis held. test386 reaches code FFh and its output matches the
reference on every byte.**

```
post 00 01 02 03 04 05 06 08 09 20 21 22 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c e0 ee ff
```

- The serial output is 44,926 lines, 3,548,969 bytes, and `cmp` finds no difference from
  `test386-EE-reference.txt`. The debug and the release build give the same result
- 104,513,187 instructions; 3.2 s on the release build, 31 s on the debug build
- It is in `tools/difftest.sh` on both builds, which now has 33 checks; all pass. A missing ROM is
  reported as skipped
- ELKS, FreeDOS and the seventeen traces still pass

How it went, by the code the ROM stopped at:

| Stopped at | Cause | Fix |
|---|---|---|
| 08 | Expected: protected mode did not exist | Descriptor caches with limits and rights, CR0.PE, paging, fault delivery, privilege changes, virtual-8086 mode (`src/prot.goose`, and most of `src/state.goose`) |
| 09 | A timer interrupt arrived as soon as the ROM ran STI. The ROM replaces the BIOS, so nothing had set up the interrupt controller, but g86m started it as the BIOS leaves it | In ROM mode the controller starts fully masked and the timer stopped |
| 12 | `LOCK MOV` must be an invalid opcode. g86m ignored the LOCK prefix | LOCK is accepted only on the instructions that may take it, with a memory destination |
| 1A | `ENTER` with a 32-bit operand on a 16-bit stack: the frame pointer pushed for nested levels is the raw ESP, upper half included, and the new top of stack is probed for writing | Followed rustx86, which had worked both out against this same stage |
| FF, output one byte long | The serial port's baud-rate divisor was recorded as a byte sent | The data register is the divisor while the divisor latch is open |

Stages 09, 20 (ring 3), 21 (virtual-8086 mode), 0B–11 (including page faults) and 13–19 passed the
first time they were reached. The trace comparison against rustx86 that the card planned for a halt
was not needed: each stop was found from the listing file and the last lines of g86m's own trace.

How faults are done: a fault abandons the instruction from wherever it is found. `raise` records
the fault and uses Goose's long-distance return (`return false from exec_one`) to leave every
frame in between; `step` then restores the registers saved at the start of the instruction and
delivers the fault. The compiler checks that every function that can fault is only ever called
inside `exec_one`. That check caught one real mistake in the design before it ran: interrupts were
delivered from the run loop, outside `exec_one`, where a fault in the delivery had nowhere to go.
Delivery moved inside. (Notes on this are in [goose-notes.md](goose-notes.md).)

One of g86m's own tests had to change. `u_stack` used a repeat count above FFFFh with a 32-bit
address size in real mode, which runs past the 64 KB segment. rustx86 allows it; g86m now raises a
general protection fault, as a 386 does. The count was reduced.

Speed: bench.bin takes 6966–7156 ms on the release build = **about 52 MIPS**, down from about 78.
Each instruction now copies the CPU state for a possible fault, each memory access checks its
segment's limit and rights, and every call that can fault tests a flag on return. Nothing was done
to win any of it back.

What this does not cover:

- **Task switching.** A task gate, a jump or call to a task segment, and IRET with NT set stop the
  machine with a message. test386 only tests them in its 128 KB build, which was not used; code
  22h appears in the trail above because the 64 KB build passes through that stage without testing
- **There is no TLB.** Every access walks the page tables. Software that depends on a stale
  translation surviving until it reloads CR3 would see different behaviour; test386 does not
- **Memory is still 1 MB** and physical addresses wrap there. test386 stays inside it
- **Debug registers, the single-step trap, and the resume flag** are not implemented
- **Hardware interrupts in protected mode** go through the same delivery code but no test raises one

## E010: Where the interpreter's time goes (2026-11-13)

Speed fell from about 105 MIPS (M3) to about 78 (M4a) to about 52 (M4b) with nothing done to win it
back, and Linux will need on the order of a billion instructions to boot.

Baseline on the release build, median of five runs:

| Benchmark | What it is | Time | Speed |
|---|---|---:|---:|
| bench.bin | 369,095,178 instructions, a 10-instruction loop in 16-bit real mode | 6934 ms | about 53 MIPS |
| test386 | 104,513,187 instructions, mostly 32-bit protected mode with paging | 3160 ms | about 33 MIPS |

- **Hypothesis**: Most of the time is in a few fixed costs paid on every instruction or every memory
  access, not in the instructions themselves. The candidates, in the order I expect them to matter:
  (1) copying the whole CPU state at the start of every instruction for a possible fault,
  (2) fetching code one byte at a time through the limit check and the paging check,
  (3) writing six flags to memory after every arithmetic instruction,
  (4) the page-table walk on every access when paging is on (test386 only).
- **What changed since last time**: Nothing in the code. This card profiles before changing
  anything, because E002 guessed at a cause and never confirmed it.
- **Next move for each result**:
  - The profile shows one of the candidates on top → fix that one first, measure both benchmarks,
    run the whole suite, then profile again
  - The profile is flat (no function above about 15%) → the cost is spread through the main
    dispatch function and a profile by function cannot split it; switch to removing one candidate
    at a time and measuring the difference
  - A fix gives less than 5% on both benchmarks → take it out again unless it makes the code simpler
- **Cut-off**: The same day. The goal is not a number; it is to know what the fixed costs are and to
  remove the ones that are cheap to remove. Every change must leave `tools/difftest.sh` at 33 of 33.

### Result

2026-11-13. **The hypothesis was half right: the time is in fixed per-instruction costs, but not the
ones I listed first.** Release build, median of five runs:

| Benchmark | Before | After | Change |
|---|---:|---:|---:|
| bench.bin (real mode) | 6934 ms, about 53 MIPS | 5531 ms, about 67 MIPS | 20% less time |
| test386 (protected mode, paging) | 3160 ms, about 33 MIPS | 1946 ms, about 54 MIPS | 38% less time |

`tools/difftest.sh` is at 33 of 33 after the changes, and test386's output is still byte for byte
the reference.

What the measurements said, in the order they were taken:

| Step | bench | test386 | Kept |
|---|---:|---:|---|
| Baseline | 6934 | 3160 | |
| Ablation: no state copy per instruction (not correct) | 6829 | - | no: 1.5%. Candidate (1) was wrong |
| Ablation: arithmetic sets only ZF and CF (not correct) | 6754 | - | no: 2.6%. Lazy flags would not pay; candidate (3) was wrong |
| Code page cache: translate once per page of code, read bytes directly | 6744 | 2388 | yes |
| Two-level opcode dispatch | 5866 | 2059 | yes |
| Big arrays declared last; three tests before the prefix loop | 5423 | 2089 | yes |
| One-entry caches for data reads and writes | 5559 | 1925 | yes: 8% on test386, within noise on bench |

The profile by function was the flat case the card allowed for: 53% in `exec_one` itself, which a
function profile cannot split. What broke it open was counting host instructions. A loop of NOPs
ran at 16 ns per instruction, and `/usr/bin/time -l` reported 104 billion host instructions for 400
million NOPs: **261 host instructions per NOP**. Stepping one NOP in the debugger and listing what
ran showed a long straight line of code, no loop, and three causes:

- **Goose compiles an integer `match` to a chain of comparisons**, and clang turns such a chain
  into a jump table only when the arms are plain values. The opcode `match` had ranges
  (`0x40..0x48`), so it stayed a chain: an opcode near the end paid for every arm before it.
  Matching first on `op >> 4` (sixteen plain values, which does become a jump table) and then
  within the row cut that to a dozen comparisons at most
- **Every instruction byte went through four calls** (`fetch8`, `lin_read`, `translate`, and a
  checked division by 8 for the width). Each call that can fault also tests a flag on return
- **Globals after the 1 MB RAM array were more than a megabyte from the start of the block**, so
  each access to the CPU state took three instructions instead of one. Goose lays globals out in
  the order their files are first imported; moving the big arrays to a file imported last put the
  state near the start

After the changes a NOP costs 209 host instructions in all, 146 of them inside `exec_one`.

What this leaves:

- **The fixed cost is still about 200 host instructions per guest instruction.** What remains is
  the per-instruction prologue (saving a dozen registers, resetting the decode state, the checks
  for a pending fault, an interrupt and a BIOS entry), about 58 instructions in the run loop
  (the state copy, the timer countdown, the trace and script checks), and the opcode body
- **The lasting fix is not to decode every time.** rustx86 got its speed from a cache of decoded
  instructions; g86m decodes from bytes on every execution. That is a design change, not a tweak
- **E002's question is still open**: nothing here tested whether byte writes to RAM make the
  compiler reload the CPU state
- The caches were checked by test386 and the two operating systems, but no test changes a page
  table entry and then relies on the old translation, which is what a cache makes possible

## E011: Load a Linux kernel and see how far it gets (M5a, 2026-11-13)

M5 is the last stage: 32-bit Linux with a busybox shell. rustx86's record of the same stage says it
took five things: memory beyond 1 MB, a boot path that loads the kernel directly instead of going
through a BIOS, a CPU that answers as an i686 (CPUID, TSC, CMPXCHG8B, CMOV and the 486's
instructions), an x87 FPU (the kernel will not start without one), and a serial port for the
console. The FPU is the largest.

This card is the first three that need no CPU work: memory, the boot path and the serial port.

- **Hypothesis**: With 128 MB of RAM, the Linux boot protocol's 32-bit entry (kernel at 1 MB, zero
  page with the memory map, command line and initramfs, flat segments, ESI pointing at the zero
  page) and a 16550 serial port, the kernel (Alpine's Linux 6.18, `vmlinuz-lts`, the one rustx86
  boots) decompresses itself and starts. It then stops at the first thing a 386 without an FPU
  lacks, and the stop names it.
- **What changed since last time**: Until now memory was 1 MB and wrapped there. The machine keeps
  its 16-bit behaviour (wrap at 1 MB, BIOS services) for boot sectors, floppies and ROMs; a Linux
  kernel image gets the 32-bit machine.
- **Next move for each result**:
  - Stops on an unimplemented opcode or an invalid-opcode fault in the kernel → list what it
    needed; that list is the work for the CPU step (M5b)
  - The kernel prints that the CPU is too old or has no FPU → the same, and the message goes in
    the record
  - Hangs or faults before printing anything → the decompressor ran wrong. It is plain 386 code,
    so that is a bug test386 did not catch: compare the trace with rustx86's from the entry point
  - Reaches user space → not expected; if it happens, measure the instruction count and the time
- **Cut-off**: The same day. The PR records where it stops; it does not have to boot.

### Result

2026-11-13. **The hypothesis held. The kernel decompresses itself, starts, and stops at the first
486 instruction.**

```
g86m: fault 6 at 0060:c4a53859  bytes: f0 0f b1 13 75 11 8b 5d fc c9
g86m: fault 6 at 0060:c412ccf6  bytes: f0 0f b1 73 0c 0f 85 47 02 00
steps 393939741 halted true fault false ms 8809 at 0060:c409aeba
```

- `F0 0F B1` is `LOCK CMPXCHG`, an instruction the 486 added. g86m raises an invalid-opcode fault,
  as a 386 would; the kernel's early fault handler uses the same instruction and faults again,
  then halts
- By then the kernel has run 393,939,741 instructions: the decompressor, and the kernel proper at
  virtual address C0000000h and up with paging on. Nothing in those 394 million instructions
  stopped on something unimplemented or went visibly wrong, though with no output there is no
  proof it went right either
- It printed nothing, even with `earlyprintk=serial`: it stopped before the serial console was
  set up
- 8.8 s on the release build, about 45 MIPS for this stretch
- `tools/difftest.sh` is still at 33 of 33; bench.bin is unchanged at about 5.4 s

Two debugging options were added on the way and are staying: `--trace-after N` starts the trace
late in a run (the first attempt to see why the kernel halted would have written 394 million trace
lines), and `--faults` reports every fault except page faults.

What this leaves for the CPU step (M5b), from rustx86's record and this run:

- `CMPXCHG` first, then the rest of what a kernel built for i686 uses: `XADD`, `BSWAP`, `INVLPG`,
  `WBINVD`, the WP bit in CR0, the AC and ID bits in EFLAGS, `CPUID`, `RDTSC`, `CMPXCHG8B`, `CMOVcc`,
  and `RDMSR` / `WRMSR` answering with a general protection fault
- After that the FPU (M5c)

Not looked at: memory use. A run now holds about 270 MB resident, for 128 MB of guest RAM.

## E012: Make the 32-bit machine an i686, and see what the kernel wants next (M5b, 2026-11-13)

- **Hypothesis**: With the instructions the 486, the Pentium and the P6 added (`CMPXCHG`, `XADD`,
  `BSWAP`, `INVLPG`, `WBINVD`, `CPUID`, `RDTSC`, `CMPXCHG8B`, `CMOVcc`, the long NOP), the WP bit
  in CR0, the AC and ID bits in EFLAGS, and `RDMSR` / `WRMSR` answering with a general protection
  fault, the kernel gets past `LOCK CMPXCHG`, sets up its serial console, and prints. It then
  stops for want of an FPU, and says so.
- **What changed since last time**: E011's machine was a 386. The identity now depends on what is
  booted: a Linux kernel gets an i686 (CPUID family 6, with TSC, CX8 and CMOV, and not yet FPU);
  boot sectors, floppies and ROMs keep the 386, so that FreeDOS and ELKS see what they saw
  before (E007 is what happens when the answers to CPU tests do not agree). The 32-bit machine
  also runs its timer at 64 instructions per tick, rustx86's ratio, instead of 4.
- **Next move for each result**:
  - The kernel prints and stops asking for an FPU → open a PR; the FPU is the next step (M5c)
  - It stops on another instruction → add it if it belongs to these CPU generations, and note it
  - It prints but then hangs or panics for a reason that is not the FPU → read the message; if it
    is about time (calibration, a clock source), look at the timer ratio and the TSC first
  - Output looks wrong (garbled, repeated) → the serial port's interrupts; check with rustx86's
    output for the same kernel
- **Cut-off**: The same day. The new instructions get trace or self-check tests before the PR,
  whatever the kernel does.

### Result

2026-11-13. **The hypothesis held. The kernel prints its log on the serial console and stops for
want of an FPU, saying so.**

```
[    0.000000] Linux version 6.18.35-0-lts (buildozer@build-3-24-x86) (cc (Alpine 15.2.0) 15.2.0, ...
[    0.000000] BIOS-e820: [mem 0x0000000000100000-0x0000000007ffffff] usable
[    0.000000] 128MB LOWMEM available.
[    0.000000] Checking if this processor honours the WP bit even in supervisor mode...Ok.
[    0.000000] printk: legacy console [ttyS0] enabled
[    2.756672] APIC: Keep in PIC mode(8259)
[    2.757181] Calibrating delay loop (skipped), value calculated using timer frequency.. 152.72 BogoMIPS (lpj=76362)
[    2.760411] x86/fpu: Giving up, no FPU found and no math emulation present
```

About a hundred lines of kernel log come out before it gives up. `tools/difftest.sh` now has 37
checks, all passing: a trace test for the new instructions (`v_686`, 386 lines, matched rustx86 on
the first run), a self-check for what the i686 says about itself (`s_686`), CPUID being an invalid
opcode on the 386 (added to `s_386`), and the kernel reaching its version line.

It stopped once on the way, and not where the card expected:

| Symptom | Cause | Fix |
|---|---|---|
| The log stopped after `APIC: Keep in PIC mode(8259)` and the kernel ran on to the instruction limit | It was calibrating the TSC against timer channel 2: it loads a count, then polls port 61h for the channel's output bit. g86m had no channel 2 and that bit never came on | Channel 2 counts from the virtual time it was loaded at; port 61h reports its output |

The card's guess for a hang was "the timer ratio and the TSC", which pointed at the right
neighbourhood; the listing of what the kernel does at that point (from its source, `pit_calibrate_tsc`)
named the port.

What the log shows that is not right yet, none of it stopping the boot:

- `unchecked MSR access error: WRMSR to 0x8b` and `RDMSR from 0x8b`, twice, with call traces: the
  microcode-revision probe. g86m answers with a general protection fault, as rustx86 does; the
  kernel reports it and carries on
- `x86 CPU feature dependency check failure: CPU0 has 'cmov' enabled but 'fxsr' disabled`: the
  feature set claimed (TSC, CX8, CMOV) is not one any real CPU had
- `tsc: Fast TSC calibration failed`: expected; the slow method then works
- `Unable to read current time from RTC`: there is no CMOS clock

Not done: nothing here measures whether the instructions run correctly inside the kernel beyond
the kernel's own behaviour. `v_686` covers them in real mode only.

## E013: An x87 FPU backed by f64, and boot Linux to a shell (M5c, 2026-11-14)

- **Hypothesis**: The FPU is the last thing between the kernel and user space. With an x87
  whose registers are `f64` (what rustx86 did), the FPU bit claimed in CPUID and the ET bit set
  in CR0, the 6.18 kernel gets through its FPU set-up, unpacks the initramfs, and busybox gives
  a shell prompt on the serial console.
- **What changed since last time**: E012's machine skipped the operand of every escape opcode
  (D8 to DF) and said it had no FPU. Now the i686 executes them: the register stack, the control,
  status and tag words, loads and stores in the three real and three integer formats, arithmetic
  and comparison, the transcendental instructions through libm, and FNSAVE/FRSTOR. Device-not-
  available (vector 7) is raised when CR0 has EM or TS set. The 386 machine is left as it was.
  Rounding control is honoured: directed rounding is made from the sign of the exact residual, as
  rustx86 does. Extended precision is not: a register holds 53 bits of mantissa, not 64, except
  that an 80-bit value loaded and stored again untouched keeps all its bits.
- **Next move for each result**:
  - A shell prompt → run `echo`, `ls`, `uname -a`, and the two commands rustx86's history says an
    absent FPU breaks (`sleep 3` taking three seconds of guest time, `printf '%f' 3`); add a
    scripted session to `tools/difftest.sh`; open a PR
  - The kernel stops on an instruction g86m does not have (FXSAVE, an SSE one, a missing x87
    one) → add it if a P6 without SSE would have it; if the kernel wants FXSR, read why it thinks
    the CPU has it before adding anything
  - The kernel panics or hangs before user space → read the message; the candidates in order are
    the FPU self-test (`fpu__init_check_bugs`, the FDIV check), the missing CMOS clock, and the
    interrupt controller
  - User space starts but a program misbehaves → trace the escape opcodes it runs, compare the
    same sequence against rustx86 with a trace test
- **Cut-off**: The same day. Whatever the kernel does, the FPU gets trace tests against rustx86
  (results stored to memory and loaded into integer registers, since the trace has no FPU
  state) and a self-check before the PR.

### Result

2026-11-14. **The hypothesis held on the first boot. The kernel finishes, unpacks the initramfs,
and busybox gives a shell on the serial console.** About 1.9 billion instructions and 41 seconds
of host time from the kernel's first instruction to the prompt.

```
[    2.760645] x86/fpu: x87 FPU will use FSAVE
[   11.082721] Run /init as init process
~ # uname -a
Linux (none) 6.18.35-0-lts #1-Alpine SMP PREEMPT_DYNAMIC 2026-06-09 12:34:47 i686 Linux
~ # cat /proc/uptime; sleep 3; cat /proc/uptime
13.69 0.07
16.72 3.06
~ # grep flags /proc/cpuinfo
flags		: fpu tsc cx8 cmov cpuid
```

No instruction was missing: the kernel is content with FSAVE and never asked for FXSAVE or SSE.

What was added besides the FPU, because a shell that cannot be typed at proves little:

- A serial console. Started from a terminal with a kernel image, g86m puts the terminal in raw
  mode and connects it to the guest's serial port, paced against real time; Ctrl-] leaves
- `--wait` and `--type` act on the serial port when the guest's console is one. A wait looks only
  at output that came after the previous wait matched

`tools/difftest.sh` now has 43 checks, all passing. New: three trace tests of the FPU against
rustx86 (`v_fpu1` to `v_fpu3`, 363 lines; the first two matched on their first run), a self-check
for what rustx86 cannot judge (`s_fpu`), a scripted Linux session (uname, `printf '%f' 3`, awk's
square root and arctangent, `sleep 3` taking three seconds of guest time), and the serial console
driven through a pseudo-terminal (`sleep 3` took 3.06 s of real time).

Two things were wrong on the way:

| Symptom | Cause | Fix |
|---|---|---|
| awk printed `atan2(1,1)*4` as 0 | For the D9 F0 to FF instructions the r/m field is part of the opcode; the code took it as a register number and used ST(3) where FPATAN means ST(1). The same slip was in FYL2X, FYL2XP1, FPREM, FPREM1 and FSCALE | They read ST(1) |
| `v_fpu3` differed from rustx86 at one line | `FLD ST(0)` of an 80-bit value: g86m copies all 64 mantissa bits, rustx86 keeps 53. g86m is the one that matches real hardware | The test stores the value without copying it; the copy is checked in `s_fpu` |

**What is wrong, and known: floats are printed truncated, not rounded.**

```
~ # printf '%f %g %e\n' 3 0.1 12345.678
3.000000 0.0999999 1.234567e+04
```

The right answers are `0.1` and `1.234568e+04`. musl's printf decides whether to round the last
digit up by adding a small number to 2^64 and seeing whether the sum changed. With the 64-bit
mantissa of a real x87 it changes; with the 53 bits of an f64 it never does, so nothing is ever
rounded up. This is the cost of the f64 registers that the card accepted, and it is larger than
the card thought: not "the last bits of a long double" but the last digit of every printed float.
rustx86 has the same registers and by the same reasoning the same answer; that was not run.
The fix is arithmetic on the 80-bit format itself (add, subtract, multiply, divide, square root
in integers, 64 bits of mantissa), with f64 kept only for the functions that go through libm.

Not done, and not needed to get here: FBLD and FBSTP (the machine stops and says so if one is
met), floating-point exceptions (none is ever raised), the instruction and operand pointers in
the saved environment (written as zero), FXSAVE and SSE, a disk, a network card, a clock chip.
Whether FCOMI on real hardware clears OF, SF and AF was not checked; g86m leaves them, as
rustx86 does.

## E014: Arithmetic on the 80-bit format, so that printf rounds (M5d, 2026-11-14)

- **Hypothesis**: The truncated floats of E013 come from one thing only: results of FPU
  arithmetic are cut to the 53 mantissa bits of an f64. If add, subtract, multiply and divide are
  done in integers on the 80-bit format (64 bits of mantissa, rounded as the control word says),
  comparison looks at all 80 bits, and conversion to and from 64-bit integers is exact, then
  `printf '%g %e' 0.1 12345.678` in the guest prints `0.1 1.234568e+04`.
- **What changed since last time**: E013 computed every result as an f64. Now a result of the four
  operations is an 80-bit value; f64 is used only where an operand is not an ordinary number (zero
  times something, infinity, NaN, a denormal), where the result leaves the exponent range, for the
  square root, and for the functions that go through libm. The trace tests set the precision
  control to 53 bits, where rustx86's f64 arithmetic is the right answer, so they stay comparable.
- **Next move for each result**:
  - printf prints both numbers rounded → add them to the scripted Linux session, add a self-check
    for 64-bit results (1/3, 1 + 2^-63, 2^64 + 1.5, a 64-bit integer through the stack), open a PR
  - Still truncated → trace the escape opcodes of that printf (a `--trace-after` run filtered to
    D8-DF) and find which instruction in musl's rounding test still loses bits; the candidates
    are the comparison and the load of the `2/LDBL_EPSILON` constant
  - Rounded, but another program's output changes for the worse → compare that sequence at 53-bit
    precision against rustx86 to tell a new bug from a precision difference
- **Cut-off**: The same day. If the integer arithmetic cannot be made to agree with rustx86 at
  53-bit precision on the existing three trace tests, it does not go in.

### Result

2026-11-14. **The hypothesis held. printf rounds.**

```
~ # printf '%f %g %e %.17g\n' 3 0.1 12345.678 0.1
3.000000 0.1 1.234568e+04 0.10000000000000001
~ # awk 'BEGIN{print 1/3, sqrt(2), exp(1), atan2(1,1)*4, 2^0.5, int(-3.7), 1e300*1e10, 0.1+0.2}'
0.333333 1.41421 2.71828 3.14159 1.41421 -3 inf 0.3
```

It worked on the first build that compiled; nothing had to be traced.

At 53-bit precision the integer arithmetic agrees with rustx86 on all three trace tests (365
lines), including the three directed rounding modes and 24-bit precision, which rustx86 gets from
the residual and g86m now gets from the bits themselves. To make the comparison fair the tests
set the precision control to 53 bits and no longer do arithmetic on the built-in constants.

`tools/difftest.sh` has 45 checks, all passing. New: `s_fpu80`, a self-check for results that
need 64 bits (1/3 to nearest, rounded down, and at 53 bits; (1/3) * 3 = 1; 1 + 2^-63; 2^64 + 1.5
against 2^64 at both precisions; a 64-bit integer through the stack), and the two printf answers
in the scripted Linux session. Boot time is unchanged (41.5 s to the shell).

What still goes through f64, with 53 bits: the square root, the functions computed by libm
(sine, cosine, tangent, arctangent, the logarithms, 2^x - 1), FPREM and FPREM1, the built-in
constants (pi and the logarithms are loaded as f64 values, 11 bits short), a store to a 32-bit
real (rounded twice: to f64, then to f32), and arithmetic on denormals or with a result outside
the exponent range. No guest program was seen to depend on any of these.

## E015: Where the Linux boot spends its time (2026-11-14)

- **Hypothesis**: Under Linux the three one-entry translation caches of E010 miss far more often
  than under test386, and each miss walks the two-level page table (two memory reads, four
  checks, two possible writes). test386 runs in a handful of pages; a kernel alternates between
  its code, its stack and data spread over many pages, and a one-entry cache keeps only the last.
  If so, more than one translation per ten instructions is a miss, and a real TLB (a few hundred
  entries, direct-mapped, separate for reads and writes) removes most of them.
- **What changed since last time**: E010 measured bench.bin and test386. This measures the
  workload that matters now: the boot to the busybox prompt (about 1.9 billion instructions,
  41 s, about 46 MIPS, where test386 runs at 54). First with counters, not with a fix: misses per
  instruction for code, reads and writes, and a host profile by function of the same run.
- **Next move for each result**:
  - Misses are above 0.1 per instruction → build the TLB; flush it where the one-entry caches are
    flushed now; measure the boot again
  - Misses are rare (below 0.02 per instruction) → the hypothesis is wrong; go by the host
    profile: if a function other than `exec_one` holds more than 15%, look there; if it is flat,
    count host instructions per guest instruction on the hottest guest loop, as E010 did
  - The boot spends a large share of its instructions waiting (calibration loops, delay loops,
    the idle loop not halting) → that is not interpreter speed; look at how virtual time advances
    (the 64 instructions per timer tick) before touching the interpreter
  - A fix gives less than 5% on the boot → take it out again unless it makes the code simpler
- **Cut-off**: The same day. `tools/difftest.sh` stays at 45 of 45, and test386's output byte for
  byte the reference, after every change that is kept. No decoded-instruction cache in this
  round: that is a design change and gets its own card.

### Result

2026-11-14. **The hypothesis was wrong about the cost. The page-table walks were as frequent as
predicted and nearly free; the time was in calls.** Release build, same machine, same day:

| Benchmark | Before (main) | After | Change |
|---|---:|---:|---:|
| Linux boot to the shell prompt, 1,651,240,001 instructions | 43.3 s, 750 billion host instructions | 32.3 s, 584 billion | 25% less time |
| test386 | 2284 ms, about 46 MIPS | 1511 ms, about 69 MIPS | 34% less time |
| bench.bin (real mode) | 5919 ms, about 62 MIPS | 4449 ms, about 83 MIPS | 25% less time |

The boot runs the same number of guest instructions before and after, to the last one: none of
this changed what the guest sees. `tools/difftest.sh` is at 45 of 45 and test386's output is
byte for byte the reference.

What was measured, in order:

| Step | Linux boot | Kept |
|---|---:|---|
| Baseline, with counters: 0.12 page-table walks per instruction | 44.3 s | |
| A TLB: 256 entries each for reads and writes, for supervisor and user. Walks fell from 197 million to 4.9 million | 44.0 s | yes, see below |
| 16- and 32-bit memory accesses and instruction operands taken at once, not byte by byte | 41.9 s | yes |
| Globals reordered and padded so that the CPU state is aligned (tried eight paddings) | 1.5% fewer host instructions on a micro-benchmark | no |
| The run loop works out the next event (timer, script, limit) and runs to it, instead of testing for each after every instruction | 39.4 s | yes |
| `inline fn` on the small helpers of the instruction path | 32.0 s | yes, all but one |

- **The TLB was what the card predicted would help, and at first it did nothing**: forty times
  fewer walks, the same time. A walk is two memory reads and a few tests; 0.12 of them per
  instruction is about ten host instructions out of 450. Measured again at the end, with the
  other costs down, the TLB is worth 2.6% of the host instructions and about 4% of the time. It
  stays: it is small, and it removes the flush of every cached translation at each change of
  privilege level
- **What broke it open was the same thing as in E010: counting.** `/usr/bin/time -l` said 447
  host instructions per guest instruction for the boot. A loop of one instruction in 32-bit
  protected mode (`probe/bench32.asm`) said about 230 of those are there for a NOP: the fixed
  cost. Stepping one guest instruction in the debugger and listing what ran gave 227 host
  instructions: 101 in `exec_one`, 56 in the run loop, 48 in `fetch8` for one byte, 22 in the
  two register accessors
- **The small helpers were not being inlined**, neither by Goose nor by clang, which stops once
  the caller is as big as `exec_one`. Every `fetch8`, `regw`, `seg_read` was a call: registers
  saved and restored, and after each call that can fault, a test of the fault flag. `inline fn`
  on 57 helpers took the guest instruction above from 227 host instructions to 156 and the boot
  from 678 to 554 billion
- **Inlining everything costs build time.** With `decode_modrm` inlined too the binary is 859 KB
  and a release build takes 15 s, against 199 KB and 1.4 s before. Leaving that one function as
  a call gives 413 KB and 4.7 s, and the boot is within 2% (32.3 s against 32.0 s). That is
  what was kept
- **Alignment was a wrong guess.** Goose packs globals with no padding, so 32-bit fields sit at
  odd addresses and arm64 needs a separate add to reach each one. Lining them up changed the
  count by 1.5%: the add is there, but it is one instruction among hundreds

What this leaves: a NOP still costs about 150 host instructions. What remains is spread thin:
saving and restoring registers around `exec_one` (14), the checks for a pending fault, an
interrupt and a BIOS entry (12), resetting the decode state (14), fetching the opcode byte
(about 35), the prefix and LOCK tests (10), the dispatch (10), and the copy of the CPU state in
the run loop (13). The next step that is not thin is the one this card excluded: not decoding
the same instruction again every time it runs.

### Addendum: with build time no object

2026-11-14. The owner's answer to the build-time trade-off above was to ignore it: pick what runs
fastest. So the options that had been held back, or not tried because they cost build time, were
measured. Median of three runs each; the kept configuration is the first row.

| Variant | Binary | bench.bin | test386 | Linux boot |
|---|---:|---:|---:|---:|
| Kept: 57 helpers inline, `decode_modrm` a call | 413 KB | 4423 ms | 1521 ms | 32.2 s |
| `decode_modrm` inline as well | 859 KB | 5677 ms | 1418 ms | 31.9 s |
| `decode_modrm` inline for 32-bit addressing, a call for 16-bit | 760 KB | 5769 ms | 1493 ms | 33.1 s |
| Kept, compiled with `-O3` | 428 KB | 4471 ms | 1419 ms | 32.2 s |
| Kept, with `-O3 -mcpu=native` | 428 KB | 4533 ms | 1537 ms | 32.7 s |
| Kept, with a profile of the Linux boot (`-fprofile-instr-use`) | 424 KB | 4952 ms | 1517 ms | 32.5 s |

**Nothing here is faster where it counts.** Inlining `decode_modrm` is 1% on the boot, which is
inside the run-to-run spread, and costs 28% on the real-mode benchmark; splitting it was worse on
all three. The compiler's own options do nothing: `-O3`, tuning for this CPU and a profile of the
boot all land within the noise on the boot, and the profile makes the real-mode benchmark slower.
(The two `-O3` rows are the same size; test386 differs by 8% between them, which is the size of
the noise on that benchmark and the reason the boot is the one to go by.)

The flags were passed through `goose build --cc` with a wrapper script that appends them after
Goose's own `-O2`. The wrapper is not kept, since none of its uses was.

So the configuration stays as it was. Being allowed to spend build time buys nothing at this
point; the interpreter's remaining cost is in what it does for each instruction, not in how well
that is compiled.

## E016: Check the instruction bytes once per instruction, not once per byte (2026-11-14)

- **Hypothesis**: After E015 a guest instruction still pays for each byte it fetches: a segment
  limit test, a page comparison, a physical-address mask and a RAM range test, and a wrap test on
  the instruction pointer, about 35 host instructions for the opcode byte alone, and an
  instruction has two to six bytes. One test at the start of the instruction ("the next 16 bytes
  lie in the page already translated, inside the segment and inside RAM") makes every fetch in
  that instruction a plain load. On the Linux boot that should remove more than a tenth of the
  host instructions.
- **What changed since last time**: E015 named a decoded-instruction cache as the next step.
  This is a smaller step toward the same cost, taken first because it cannot go stale: nothing is
  remembered from one execution to the next, so code that modifies itself needs no handling.
  What the cache would add on top (not fetching at all) is measured against this, not against
  E015.
- **Next move for each result**:
  - More than 10% fewer host instructions on the boot → keep; then list what a NOP still costs
    and decide whether the cache is worth its invalidation logic
  - Less than 5% → the fetches were not where the cost was; take it out, and go by the listing of
    one instruction again before building anything larger
  - A test fails → the window is wrong at an edge (page end, segment limit, 64 KB wrap in 16-bit
    code, an instruction of more than 15 bytes); fix the condition, not the test
- **Cut-off**: The same day. `tools/difftest.sh` at 45 of 45, test386 byte for byte, and the boot
  must still take exactly 1,651,240,001 instructions to the prompt.

### Result

2026-11-14. **The hypothesis was wrong. One check per instruction instead of one per byte removed
2.2% of the host instructions on the boot (584 to 571 billion, 32.3 s to 31.6 s), under the 5% the
card set, and it was taken out.** The boot still took 1,651,240,001 instructions and test386 was
byte for byte the reference with it in.

The estimate behind the card was stale. The 35 host instructions for an opcode byte were counted
before E015 inlined `fetch8`; after it, a fetch on the fast path is already short, and the page
comparison and limit test that the window removes are a few instructions each.

With the card's own next move ("go by the listing of one instruction again") the debugger stopped
responding in this environment, three times, so the question was put differently: is the average
high because of something other than ordinary instructions? Three things were measured instead.

| Question | Measurement | Answer |
|---|---|---|
| Do repeated string instructions hide many iterations in one step? | Counted them on the boot: 14.5 million string instructions, 78 million iterations, against 1,651 million instructions | No. About 3% of the work at most |
| Is the boot waiting, in loops that run until time has passed? | Booted with 8, 16, 32, 64, 128 and 256 instructions per timer tick | No. See below |
| Is a memory instruction much dearer than a NOP? | `probe/bench32.asm`, after E015: NOP 197, `mov eax, [ebx+8]` 264, `add [ebx+8], eax` 307 host instructions per guest instruction, each averaged with the loop's DEC and JNZ | Dearer, not by a multiple |

Instructions to the prompt, by instructions per timer tick:

| Per tick | 8 | 16 | 32 | 64 | 128 | 256 |
|---|---:|---:|---:|---:|---:|---:|
| Millions of instructions | 2171 | 1768 | 1639 | 1651 | 1767 | 2055 |
| Seconds | 45.4 | 35.9 | 32.3 | 31.8 | 33.5 | 38.1 |

The count has a minimum between 32 and 64. Below it the timer interrupts more often for the same
work; above it the kernel's time-based loops run for more instructions. If the boot were mostly
waiting, the count would keep falling as the tick got shorter. It does not: the boot is work, and
the 64 that rustx86 chose is already at the bottom. (The `--tick` option used for this was not
kept.)

So both sides of "guest instructions times host instructions each" have been looked at. The left
side is at its minimum. The right side is about 350 on the boot: about 150 that every instruction
pays, and about 200 for what the instruction does, spread over decoding the operand, checking the
segment, translating the address and the access itself, none of which stands out.

What is left is not a tweak. A cache of decoded instructions would remove the opcode fetch, the
prefix tests, the reset of the decode state and the operand decode on every execution but the
first, and add a lookup and the handling of code that is written to. From the listing of a NOP
that is roughly 60 host instructions saved and 20 added, and somewhat more for instructions with
a memory operand: an estimate of 10 to 20% on the boot, for rewriting how `exec_one` gets its
operands. Not started; it needs its own card.

## E017: Remember how an instruction decodes (2026-11-14)

- **Hypothesis**: Decoding is a large share of what an instruction costs, and it is the same
  every time the instruction runs. Measured before starting, in host instructions per guest
  instruction (`probe/bench32.asm`, the loop's own cost subtracted): NOP 161; `mov eax, edx` 250;
  `lea eax, [ebx+8]` 300; `lea eax, [ebx+edx*4+8]` 344; `mov eax, [ebx+8]` 382; the same with an
  FS override 442; `mov ax, dx` (an operand-size prefix) 308. So a ModRM byte costs about 90, a
  displacement or SIB byte 50 to 90 more, and each prefix about 60. A cache that keeps, per
  instruction address, the prefixes, the opcode and the decoded operand, and replays them when
  the bytes are still the same, should take the boot below 500 billion host instructions (it is
  584 billion).
- **What changed since last time**: E016 estimated this from a listing taken before E015 and
  was wrong; this estimate is from measurements on the current build. The design is the smallest
  one that could work in Goose, which has no function pointers, so the opcode is still dispatched
  by `match`: only the parsing is skipped. An entry is validated by comparing the instruction's
  first eight bytes with the bytes it was made from, so nothing has to watch writes to memory,
  and code that modifies itself simply misses. Immediate operands are not cached; they are
  fetched as before.
- **Next move for each result**:
  - Below 500 billion → keep; measure what a cached NOP and a cached `mov eax, [ebx+8]` cost now,
    and say what the dispatch itself costs
  - Between 500 and 555 billion (5 to 15%) → keep only if the micro-benchmarks show where the
    rest went (a slow lookup can be fixed; a cache that mostly misses cannot)
  - Above 555 billion (under 5%) → take it out
  - A test fails → compare the trace with the cache switched off; the first differing line names
    the instruction whose replay is wrong
- **Cut-off**: The same day. `tools/difftest.sh` at 45 of 45, test386 byte for byte, the boot at
  exactly 1,651,240,001 instructions, and a new self-check in which code overwrites an
  instruction that has already run and runs it again.

### Result

2026-11-14. **The hypothesis held in the end, by a small margin: 501 billion host instructions on
the boot, against a target of 500. The first version made things worse.** Release build, median
of three, against main after E015:

| Benchmark | Before | After | Change |
|---|---:|---:|---:|
| Linux boot to the shell prompt | 32.3 s, 584 billion host instructions | 29.6 s, 501 billion | 8% less time, 14% fewer instructions |
| test386 | 1511 ms | 1376 ms | 9% less time |
| bench.bin (real mode) | 4449 ms | 4523 ms | no change (2% slower, inside the spread) |

The boot still runs 1,651,240,001 instructions; `tools/difftest.sh` is at 47 of 47 (two more: the
new `s_smc` on both builds); test386 is byte for byte the reference.

Host instructions per guest instruction, before and after (`probe/bench32.asm`):

| Instruction | Before | After |
|---|---:|---:|
| `nop` | 161 | 169 |
| `mov eax, edx` | 250 | 213 |
| `lea eax, [ebx+8]` | 300 | 236 |
| `lea eax, [ebx+edx*4+8]` | 344 | 246 |
| `mov eax, [ebx+8]` | 382 | 288 |
| `mov eax, [fs:ebx+8]` | 442 | 302 |
| `mov ax, dx` | 308 | 213 |
| `mov eax, 0x12345678` | 215 | 193 |
| `add eax, 5` | 369 | 318 |
| `mov [ebx+8], eax` | 378 | 290 |

A prefix is now free, and a memory operand costs about 25 to decode instead of 50 to 90. A NOP
is slightly dearer: looking it up costs as much as decoding it did.

How it got there, on the boot:

| Step | Host instructions |
|---|---:|
| Before | 584 billion |
| The cache as first written | 603 billion |
| Eight byte loads made one (see below) | 572 billion |
| The decode state as one 8-byte struct, copied whole; the two code sizes in separate halves of the table; "the page is in RAM" worked out once per page | 558 billion |
| The cached operand replayed inline; only the parser is a call | 523 billion |
| An instruction that has an entry fetches its remaining bytes without checks | 512 billion |
| A short path for a flat 4 GB data segment in the segment check | 501 billion |

- **The first version was slower than no cache.** The lookup compared eight bytes of the
  instruction with eight bytes in the entry, and reading those eight bytes was sixteen host
  instructions with eight bounds checks. Two things were wrong. The range test was in the
  caller, as a boolean, where Goose's bounds-check analysis could not use it; moved into the
  function, against the constant, the checks went. And the index was a `u32`: `ram[p + 1]` with
  32-bit wrapping arithmetic does not provably follow `ram[p]`, so clang would not merge the
  loads. With an `i64` index the eight loads are one. The same mistake was in E015's 16- and
  32-bit memory accesses, and was fixed there too
- **At 558 billion the card said to take it out** (under 5%). What decided otherwise was the
  table above: the register form of `mov` was still 71 over a NOP, for an operand that is three
  fields to load. The replay was a call; inlining it is what made the cache pay
- **Code that changes itself**: `s_smc` runs an instruction twice, overwrites its opcode, its
  ModRM byte, a displacement, a prefix, a SIB byte or an immediate, and runs it again. It passes
  with the cache on and off. With the byte comparison deliberately removed it fails, so it does
  test what it is there to test

What is not cached, and why the dispatch is the next cost: the opcode is still found by `match`,
immediates are still fetched, and a NOP still costs 169. Goose has no function pointers, so an
entry cannot hold "what to run"; it can only hold "what was parsed".

`--no-decode-cache` switches the cache off, for finding a fault in it.

### Addendum: small gains kept

2026-11-14. The cards so far said to take a change out when it gained less than 5%. The owner's
view is that small gains add up and should be kept, and the numbers bear it out. From now on a
change stays if it measurably reduces the work, and "measurably" means the host instruction count
of the Linux boot, which repeats to within 0.01% from run to run, where the time varies by a few
percent. Four changes, each of which the old rule would have dropped or never tried:

| Change | Host instructions on the boot |
|---|---:|
| After the decode cache (above) | 501.4 billion |
| The globals of `state.goose` and `exec.goose` declared widest first, `Cpu` made 128 bytes | 491.4 billion |
| At the BIOS-entry test, `bios_on` tested first instead of last | 481.5 billion |
| The arithmetic flags gathered and written to EFLAGS once per operation; shifts done in one step instead of one bit at a time | 466.3 billion |

- **The aligned globals are E015's rejected idea.** There it was 1.5% on a micro-benchmark and
  was taken out. Here it is 2% on the boot. Padding in front of the block was tried again at
  every size from 0 to 7; the odd sizes and none were equally good, so there is none
- **One reordered condition is 2%.** `cpu.ip < 256 && bios_on && ...` loaded the instruction
  pointer and compared it on every instruction; under Linux `bios_on` is false and nothing else
  needs to be looked at. Six host instructions per guest instruction
- **The flags**: each of six `set_flag` calls read EFLAGS, changed one bit and wrote it back
- **The shifts** looped once per bit position with a `match` inside the loop. SHL, SHR and SAR
  are now one step; the rotates still loop. The 4,317 lines of the two shift trace tests match
  rustx86 as before

Where that leaves the three benchmarks, against main after E015:

| Benchmark | After E015 | Now | Change |
|---|---:|---:|---:|
| Linux boot to the shell prompt | 32.3 s, 584 billion | 27.3 s, 466 billion | 15% less time, 20% fewer instructions |
| test386 | 1511 ms | 1285 ms | 15% less time |
| bench.bin (real mode) | 4449 ms | 4220 ms | 5% less time |

47 of 47; test386 byte for byte; the boot at 1,651,240,001 instructions.

### Addendum: against rustx86, on the same machine

2026-11-14. rustx86 (commit 64aba23, release build) and g86m (this branch) run the same three
workloads from the same image files. Host instructions are from `/usr/bin/time -l`.

| Workload | | rustx86 | g86m |
|---|---|---:|---:|
| bench.bin, 369 million instructions, 16-bit real mode | time | 6.8 s (54 MIPS) | 4.2 s (87 MIPS) |
| | host instructions per guest instruction | 389 | 244 |
| test386, 104.5 million instructions | time | 1.68 s | 1.29 s |
| | host instructions per guest instruction | 280 | 247 |
| Linux boot to "busybox shell" | guest instructions | 1,500 million | 1,647 million |
| | time, interpreter | 16.1 s (93 MIPS) | 27.3 s (60 MIPS) |
| | host instructions per guest instruction | 171 | 282 |
| | time, rustx86 with its JIT | 11.4 s | - |

**g86m is faster where rustx86 has no decode cache, and slower where it has one.** rustx86's
cache covers 32-bit code only and leaves 16-bit code, prefixed instructions and the less common
opcodes to its ordinary path; that is why it is at 389 and 280 on the first two and 171 on the
third. g86m is between 244 and 282 on all three.

The two caches are not the same kind. g86m's remembers how an instruction parses, and then goes
through the same `match` on the opcode and the same general code as before. rustx86's turns the
most frequent instructions (the two MOVs, the arithmetic grid, the conditional jumps, LEA, the
shifts, MOVZX, TEST: chosen by counting opcodes over a Linux boot) into a small operation each
with its own short executor, and the rest fall back. The difference between 282 and 171 is what
that buys.

The guest instruction counts differ (rustx86 runs 256 instructions per timer tick, g86m 64) and
rustx86's count is rounded up to its 10-million-instruction check, so the times are comparable
and the per-instruction figures slightly favour neither.

## E018: Short executors for the frequent instructions (2026-11-14)

- **Hypothesis**: g86m spends about 280 host instructions per guest instruction on the Linux
  boot where rustx86 spends 171, and the difference is that rustx86 gives its most frequent
  instructions an executor of their own, reached straight from the decode cache, while g86m's
  cache only saves the parsing and then runs the general code (the `match` on the opcode, the
  width tests, the general operand access). Counted on the boot: `89` and `8B` (the 32-bit MOVs)
  are 28% of all instructions; the arithmetic grid about 17%; conditional jumps about 11%; `83`
  5.6%; MOVZX 5.5%; LEA 3.8%; the shifts 5.8%. Only 3.2% of instructions have a prefix. With
  executors for those, for 32-bit code with no prefix, the boot goes below 400 billion host
  instructions (it is 466 billion).
- **What changed since last time**: E017's entry said what was parsed. Now an entry can also
  say what kind of instruction it is, and for those kinds holds everything needed: the operand,
  the immediate, the length. The kind is worked out the second time an instruction is met, from
  what the first execution recorded, so the first execution is always the general one. The
  executors call the same helpers as the general code (`alu`, `shift`, `cond`, the segment
  access), so there is one implementation of what an instruction means.
- **Next move for each result**:
  - Below 400 billion → keep; count again which opcodes are still general and add the next ones
    while each addition measurably lowers the count
  - Above 400 billion → the executors themselves are too long; list one (`mov eax, [ebx+8]`) on
    the micro-benchmark and shorten it
  - A test fails → run with `--no-decode-cache`; if that passes, the first differing trace line
    names the instruction whose executor differs from the general code
- **Cut-off**: The same day. `tools/difftest.sh` at 47 of 47, test386 byte for byte, the boot at
  exactly 1,651,240,001 instructions. The trace tests do not exercise these executors much (they
  are 16-bit code, where an instruction is only cached, not specialised), so a 32-bit protected
  mode trace test is added that runs each kind at least twice.

### Result

2026-11-14. **The hypothesis held: 313 billion host instructions on the boot, against a target of
400 (it was 466).** Release build, median of three:

| Benchmark | Before | After | Change |
|---|---:|---:|---:|
| Linux boot to the shell prompt | 27.3 s, 466 billion host instructions | 20.0 s, 313 billion | 27% less time, 33% fewer instructions |
| test386 | 1285 ms, 25.8 billion | 1194 ms, 23.7 billion | 7% less time |
| bench.bin (real mode) | 4220 ms, 90.2 billion | 4658 ms, 97.3 billion | 10% more time |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 48 of 48 (one
more: `u_short`); test386 is byte for byte the reference.

On the boot, in order:

| Step | Host instructions |
|---|---:|
| Before | 466 billion |
| 21 kinds: the 32-bit MOVs, the arithmetic grid, `83` and `81`, LEA, TEST, the shifts, Jcc, JMP, CALL, RET, NOP, PUSH, POP, INC, DEC, MOV r,imm, MOVZX | 387 billion |
| 10 more: the byte MOVs, byte arithmetic and TEST, TEST with an immediate, IMUL, SETcc | 377 billion |
| The short path in a small function of its own, in front of the general one | 362 billion |
| A run of short instructions executed without returning to the run loop | 312 billion |
| The outer function reduced to a choice, so that 16-bit code does not pay for the short path | 313 billion |

- **The run of instructions changed what the guest saw, once.** The first version took 420,000
  more guest instructions to reach the prompt. An instruction after STI runs with interrupts
  held off for that one instruction; a run that started there went on past the point where the
  interrupt was due. A run now ends after such an instruction. The instruction count was what
  showed it: every test passed
- **The 16-bit benchmark is 10% slower**, and the cause is known: every instruction now passes
  a test for "32-bit code with nothing pending" before the general path. With the short path
  inside the outer function it was 27% slower, because 16-bit code then paid for two function
  entries; making the outer function only choose brought it to 10% at no cost to the boot. What
  remains was accepted: the 16-bit guests run paced against real time and have been faster than
  they need to be since E005
- `u_short` runs each kind four times in 32-bit protected mode (general, classified, then twice
  by its executor) and matches rustx86 over 308 lines. With one executor deliberately wrong it
  fails at line 152, in the third pass, where the executors start

Host instructions per guest instruction now: NOP 126, `mov eax, edx` 135, `mov eax, [ebx+8]` 202,
`add eax, edx` 185 (measured before the run of instructions was added, which removes about 30
more from each when they follow one another). The boot averages 189.

### Addendum: is the difference from rustx86 a matter of design? (the owner's experiment)

The comparison in E017 showed g86m ahead on 16-bit code and on test386 and behind on the Linux
boot, and put that down to rustx86's short executors. The owner pointed out that this was an
inference: the three workloads are different mixes of instructions, with more paging and more
interrupts in the boot, so the code generated for the two languages could still be what differs.
The experiment that separates the two: switch rustx86's executors off and boot Linux with it. If
it then costs about what g86m cost without executors (about 280 per guest instruction), the
difference is design.

rustx86 was built with its decode cache bypassed (the path it takes when its debugger is on:
every instruction through its general `step`) and booted the same kernel:

| | Guest instructions | Host instructions | Per guest instruction | Time |
|---|---:|---:|---:|---:|
| rustx86, as built | 1,500 million | 257 billion | 171 | 16.1 s |
| rustx86, decode cache bypassed | 1,500 million | 853 billion | 568 | 51.8 s |
| g86m before E018 (parse cache, no executors) | 1,647 million | 465 billion | 282 | 27.3 s |
| g86m after E018 | 1,647 million | 311 billion | 189 | 20.6 s |

The serial output of the two rustx86 runs has the same checksum, so the bypass changed nothing
but the speed.

**It did not fall to 280; it fell to 568.** So the answer is stronger than the question asked
for. rustx86's general path is twice as costly as g86m's on this workload, as it is on the
16-bit benchmark (389 against 244): everything rustx86 has on the boot comes from its executors,
which take it from 568 to 171. Nothing here suggests that Goose's generated code is what holds
g86m back; at the same level of design the Goose interpreter is the leaner one, and with
executors g86m is at 189 against rustx86's 171.

What this does not show: that the two general paths are equally well written. rustx86's saves a
352-byte copy of the CPU for every instruction on that path, which g86m's 128-byte copy does
not; some of the 568 is that. The comparison is between two programs, not two compilers.

## E019: What the 35% between Rust and Goose in E002 is made of (2026-11-14)

- **Hypothesis**: E002 found the same fragment of an emulator 35% slower in Goose than in Rust
  and left the cause open, with aliasing as the untested candidate. Since then two things have
  been learned about the code Goose produces (E010, E015): an integer `match` with ranges is a
  chain of comparisons where Rust makes a jump table, and small helpers are calls where Rust
  inlines them. The fragment (`probe/m0.goose`) has both: a `match` over the opcode with seven
  ranges, and about twenty helpers. If those two are the 35%, then writing the Goose fragment
  with a two-level `match` and `inline fn` brings it within 10% of the Rust one, and aliasing
  is not needed to explain anything.
- **What changed since last time**: E002 compared times only. This compares host instructions
  per guest instruction as well, which separates "more instructions" from "slower instructions",
  and changes the Goose fragment one thing at a time. The Rust fragment and the workload
  (bench.bin, 369,095,178 instructions) are E002's, unchanged.
- **Next move for each result**:
  - Within 10% with both changes → the difference is what each compiler does unasked, not what
    the language can reach; say which change is worth how much
  - Still more than 10% slower → look at the two hot loops side by side in assembly for what is
    left (a reload after each write to RAM would show as loads of the CPU state that Rust does
    not have), and test aliasing directly by keeping the registers in locals
  - Goose becomes faster than Rust → check that the two still do the same work (same final
    registers, same instruction count) before believing it
- **Cut-off**: The same day. Median of five runs; the variants of the fragment are kept in
  `probe/` only if they are what the result rests on.

### Result

2026-11-14. **The hypothesis held, for a different reason than the one given. With one change the
Goose fragment is within 7% of the Rust one. The change is the `match`; `inline fn` does
nothing here.** bench.bin, 369,095,178 instructions, same final registers in every variant.
Times are the median of seven interleaved runs; host instructions and cycles from
`/usr/bin/time -l`.

| Fragment | Time | Against Rust | Host instructions per guest instruction | Cycles |
|---|---:|---:|---:|---:|
| Rust (`probe/m0.rs`, rustc 1.97.1, `-C opt-level=3`) | 1287 ms | | 52.0 | 4.0 billion |
| Goose as in E002 (`probe/m0.goose`) | 1763 ms | +37% | 61.2 | 5.4 billion |
| Goose, helpers marked `inline fn` | 1716 ms | +33% | 60.5 | 5.4 billion |
| Goose, two-level `match` (on `op >> 4`, then within the row) | 1532 ms | +19% | 60.2 | 4.7 billion |
| Goose, two-level `match`, flags written once per operation | 1553 ms | +21% | 59.9 | 4.8 billion |
| Goose, two-level `match`, RAM as 32-bit cells | 1768 ms | +37% | 62.9 | 5.5 billion |
| Goose, one `match` with every value listed, no ranges (`probe/m0_flat.goose`) | 1375 ms | +7% | 58.8 | 4.3 billion |

What each row says:

- **The 35% of E002 was mostly not extra instructions.** The original Goose fragment runs 18%
  more host instructions than Rust and takes 37% more cycles: its instructions are also slower.
  That is the signature of branches that are predicted badly, and a chain of comparisons on the
  opcode is exactly that. The two-level `match` keeps the instruction count (60.2) and removes
  a seventh of the cycles
- **Listing the values removes the rest of it.** A `match` whose arms are plain values, with
  `0x40, 0x41, ..., 0x47 =>` where there was `0x40..0x48 =>`, becomes one jump table in the C
  compiler's hands, which is what rustc makes of a `match` with ranges. Seen in the assembly:
  the Rust loop fetches a byte, bounds-tests it and jumps through one table; the two-level Goose
  loop jumps through a table of 13 rows and then compares again inside the row
- **`inline fn` does nothing here**, because in a 250-line program the C compiler had already
  inlined everything into `main`. In g86m it was worth a quarter (E015) because `exec_one` is
  too large for the C compiler to inline into
- **Aliasing, E002's untested candidate, is not it.** Writing the six flags once (so that no
  flag is read back from memory) changes nothing: the C compiler had already merged them. Giving
  RAM a different element type from every CPU field, so that a write to RAM cannot be taken for
  a write to the CPU state, makes it slightly worse
- **About 7 host instructions per guest instruction remain** (58.8 against 52.0), worth 7% in
  time. Both programs keep the CPU state in memory and fetch a byte in the same eight
  instructions. What the rest is was not found: stepping in the debugger, the tool for this,
  does not respond in this environment

**It does not carry over to g86m as it is.** g86m's dispatch was flattened the same way, by
script: one `match` over the opcode with every value listed, in `exec_general` and in
`two_byte`. All tests passed and all three benchmarks got slightly worse:

| | Two-level (kept) | One level, values listed |
|---|---:|---:|
| bench.bin | 97.3 billion host instructions | 100.2 billion |
| test386 | 23.8 billion | 24.2 billion |
| Linux boot | 312.6 billion | 315.6 billion |

So it was taken out. Why the fragment gains and g86m loses was not established. Two differences
that could matter: g86m's first-level table already sends an opcode to a row of at most sixteen,
so there was less to gain; and its general path now runs only the instructions that have no
short executor, about a tenth of a Linux boot.

What this says about the two languages, and what it does not: on this fragment the difference
between Rust and Goose is what the compilers make of a `match` over integers, and a programmer
who knows that can close most of it. It is one program of 250 lines. It says nothing about
programs that use what Rust has and Goose lacks, or the reverse.

## E020: The decompression phase, and repeated string instructions in bulk (2026-11-14)

- **Hypothesis**: The kernel image decompresses itself before it starts, and that phase is a
  large, simple part of the boot. Measured first: it is 393,896,527 guest instructions (24% of
  the boot) and 3.7 s (18%), 63 billion host instructions, 160 per guest instruction; 94% of its
  instructions already go through a short executor. So the phase is not slow per instruction;
  it is long. What can still be removed without changing what the guest does is the per-element
  cost of REP MOVS and REP STOS: each element goes through the general segment check, the
  translation and the access, about 150 host instructions, and a whole boot runs 78 million of
  them (E016). Copying a page-sized run at a time, with one translation per page, should take
  about 10 billion host instructions off the boot's 313 billion.
- **What changed since last time**: E016 counted the string iterations and set them aside as 3%.
  Under the rule adopted since (keep what measurably helps), 3% is worth having. Nothing about
  the guest changes: a repeated string instruction was already executed whole within one step.
- **Next move for each result**:
  - The boot's host instruction count falls → keep, with a test that copies overlapping regions
    in both directions of overlap and across page ends
  - It does not fall → the iterations are not where E016's estimate put them; count them per
    phase before doing anything else
  - The guest instruction count changes, or a test fails → the bulk copy differs from one
    element at a time somewhere (overlap, a page end, a fault part-way); find the case, do not
    widen the conditions
- **Cut-off**: The same day. `tools/difftest.sh` at 48 of 48, test386 byte for byte, the boot at
  1,651,240,001 instructions.

### Result

2026-11-14. **Half the hypothesis held. The boot's host instruction count falls, by 5.5 billion
where 10 were predicted; the decompression phase itself hardly moves.**

| | Before | After |
|---|---:|---:|
| Linux boot to the shell prompt | 312.6 billion host instructions, 20.0 s | 307.0 billion, 19.3 s |
| The decompression phase alone (to the instruction that turns paging on) | 63.0 billion, 3.75 s | 62.4 billion, 3.68 s |
| test386 | 1194 ms | 1162 ms |
| bench.bin | 4658 ms | 4486 ms |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 51 of 51 (three
more); test386 is byte for byte the reference.

- **The decompression phase is not where the string instructions are.** It gained 0.6 billion
  of the 5.5. Inflating is byte-at-a-time work in ordinary instructions; the bulk copies of a
  boot are later, in the kernel (clearing pages, unpacking the initramfs)
- **What the phase is**: 394 million guest instructions at 160 host instructions each, 94% of
  them already through a short executor. Of the 5.7% that are not, the largest are an
  operand-size-prefixed `8B` (1.7% of the phase), REP MOVS (1.4%), `F7` (1.3%) and `D1` (0.6%).
  There is no single thing left in it to remove; making it faster means making the short path
  faster, which helps the rest of the boot equally
- **The other way to shorten it is not to run it**: the payload is gzip (8.6 MB, to about
  20 MB). Inflating it on the host and entering the kernel where the decompressor would have
  jumped would take the phase's 3.7 s off a 19 s boot. That changes what is emulated (the
  guest's own decompressor never runs), so it is a decision and not an optimisation. Put to the
  owner, who decided against it: g86m boots a kernel image by running it

**The tests found two things, neither of them what they were written for.**

- **The first versions of both new tests did not test the bulk copy at all.** A self-check for
  overlapping copies passed; it also passed against a build in which the copy had been made
  deliberately wrong. The bulk path had a condition (no wrap of physical addresses) that is
  false on the machine the tests run on, so the ordinary path ran every time. The condition was
  wider than it needed to be: it now asks only that the page itself lies below the wrap point.
  After that the deliberately wrong build prints `N`
- **rustx86 copies overlapping dwords wrongly.** `REP MOVSD` with the destination one byte above
  the source: each dword is read whole and then written, so the next read sees three bytes of
  what was just stored. Worked by hand for `11 22 33 44 55 66 77 88 99` and two dwords: `11 11
  22 33 44 44 66 77 88`. g86m gives that, with and without the bulk path. rustx86 gives what a
  byte-by-byte copy gives. The trace test (`u_strbulk`) therefore keeps to overlaps of a whole
  element or more, and the closer ones are in a self-check with the hand-worked values
  (`s_strovl`)

The estimate of 10 billion was 78 million elements at about 130 host instructions saved each.
Either fewer of them qualify (the bulk path wants an upward copy with 32-bit addressing through
flat segments) or an element was costing less than 150; which was not measured.

## E021: A short path for memory accesses (2026-11-14)

- **Hypothesis**: An instruction that touches memory pays far more for the access than for
  anything else. Measured on main (`probe/bench32.asm`, host instructions per guest instruction,
  inside a run of short instructions): `nop` 74, `mov eax, edx` 81, `mov eax, [ebx+8]` 159,
  `mov [ebx+8], eax` 161, `add [ebx+8], eax` 269. One read costs 78 and one write 80, more than
  the whole of a register instruction. An access goes through the segment check, the one-entry
  page cache, the TLB behind it, a mask, two range tests and the load, each written to be right
  in every case. For the common case (a flat segment, an access inside one page, a page the TLB
  knows and that lies in RAM) one test of each of those and a load should do: about 25. About
  four instructions in ten of a Linux boot touch memory, so the boot should lose more than 20
  billion of its 307 billion host instructions.
- **What changed since last time**: E015 built the TLB behind the one-entry caches and E017 gave
  the segment check a short case; the access itself was never looked at as a whole. Now the
  common case is one inline path in `seg_read` and `seg_write`, in front of the existing code,
  which stays as it is for everything else. A TLB entry is only made for a page that lies in RAM
  below the point where physical addresses wrap, so a hit needs no further test of the address.
- **Next move for each result**:
  - The count falls → keep; measure what a read costs now, then go on to the flags (the next
    largest: `add eax, edx` costs 54 more than `mov eax, edx`)
  - It falls by less than half the estimate → the 78 are not in the access; list the host
    instructions of one `mov eax, [ebx+8]` from the disassembly before changing more
  - A test fails or the guest instruction count changes → a case the short path takes that it
    should not (an access across a page end, a segment that only looks flat, a stale entry after
    a change of privilege); narrow the condition
- **Cut-off**: The same day. `tools/difftest.sh` at 51 of 51, test386 byte for byte, the boot at
  1,651,240,001 instructions.

### Result

2026-11-14. **The hypothesis was wrong about where a memory access costs. The boot is 8% faster
all the same, mostly from something else found on the way, and one byte nearly cost a fifth.**

| | Before (main) | After |
|---|---:|---:|
| Linux boot to the shell prompt | 19.6 to 20.3 s, 307.1 billion host instructions, 60.4 billion cycles | 18.1 to 18.2 s, 299.2 billion, 56.8 billion |
| test386 | 1204 to 1209 ms | 1133 to 1250 ms |
| bench.bin (real mode) | 4522 to 4551 ms | 4516 to 4530 ms |

Times are from alternating runs on a machine that was not idle; the counts are what to go by.
The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 51 of 51;
test386 is byte for byte the reference.

**The short path for an access did not shorten the access.** Host instructions per guest
instruction, before and after: `mov eax, [ebx+8]` 159 and 162; `mov [ebx+8], eax` 161 and 149;
`add [ebx+8], eax` 269 and 253. A read costs what it did. The disassembly of the short executor
for `mov r32, [mem]` says why the estimate was wrong: the 78 host instructions that a read adds
are about 20 to build the address from the decoded operand (testing for a base, for an index,
unpacking each), a handful to settle the segment, and about 30 for the access, which was
already most of the way to its short form after E015 and E017. There was little left in the
part this card went after.

**What did help: not saving the whole CPU for each instruction of a run.** A run of short
instructions copied all 128 bytes of the CPU at the start of each, in case it faulted. A short
executor changes only the instruction pointer and the flags before the last point at which it
can fault, so those two are saved instead and `step` restores just them. 300.7 to 291.6 billion
on the boot when it went in. Page faults inside runs happen throughout a Linux boot, and the
guest instruction count is unchanged, which is the evidence that the restore is right.

**One byte.** The flag that says "only two fields were saved" was first a `bool`. With it the
boot was faster and the 16-bit benchmark took a fifth longer, on fewer host instructions:

| The flag | bench.bin | Linux boot |
|---|---:|---:|
| not there (main) | 97.2 billion instructions, 14.3 billion cycles | 307.1, 60.4 |
| a `bool` | 95.0, 17.2 | 291.5, 56.0 |
| an `i64` | 97.3, 14.2 | 299.2, 56.8 |

Goose packs globals. A one-byte global moves every global declared after it, in that file and
in every file imported later, by one byte. Reverting each changed file in turn showed the
slowdown came with `exec.goose`, not with the memory path; padding of 0 to 7 bytes after the
flag showed the pattern exactly: every even size gives 14.2 billion cycles on the benchmark and
about 299 billion instructions on the boot, every odd size about 17.2 billion cycles and 287 to
295 billion instructions. So an odd shift makes some later globals cheaper to address (fewer
instructions) and makes something stall (more cycles on 16-bit code). The flag is an `i64` now,
which keeps everything behind it where it was.

Not established: which global stalls. It is not the RAM array's position (shifting it by nine
different amounts changes nothing) and not the virtual-time counter (realigning only that
leaves the stall). And not collected: the 4% of instructions that an odd shift saves on the
boot. Both say the same thing: the layout of the globals in the files after `exec.goose` is
worth a card of its own.

Also in: the TLB only holds pages that lie in RAM below the wrap point, so a hit needs no
further address test; and the short path takes any upward data segment within its limit, not
only a flat one, so that 16-bit code uses it too.

## E022: The arithmetic, shift and conditional-jump executors know which operation they are (2026-11-14)

- **Hypothesis**: The roadmap said "compute the flags lazily: an arithmetic instruction costs 54
  more than a MOV". Measured before designing anything (host instructions per guest instruction,
  `probe/bench32.asm`): `mov eax, edx` 82; `test eax, edx` 101; `inc eax` 107; `add`, `sub`,
  `xor`, `and`, `cmp eax, edx` 132 to 140; `add eax, 5` 123; `shl eax, 3` 175. TEST and XOR set
  the same flags from the same kind of result, and XOR costs 33 more. The difference is not the
  flags: TEST's executor is written for one operation, while the arithmetic executors take the
  operation as a number from the opcode and sort it out when they run, in `alu`'s `match` and
  the conditions inside it. The same holds for the shifts (one general function for eight kinds
  of shift and rotate) and for the conditional jumps (sixteen conditions told apart at run
  time). So the flags themselves cost about 20, and what can be removed cheaply is the sorting
  out: an executor per operation. That should take 30 off each arithmetic instruction (17% of a
  boot), more off each shift (6%), and some off each conditional jump (11%): below 280 billion
  host instructions on the boot (it is 299 billion).
- **What changed since last time**: E021's estimate came from a difference between two
  numbers and was wrong about where the cost was. This one was taken apart first, by measuring
  instructions that differ in one respect only. Lazy flags, the roadmap's item, are not done:
  they would save about 15 of the remaining 20 on each arithmetic instruction, at the price of
  every reader of the flags in the program having to ask for them first.
- **Next move for each result**:
  - Below 280 billion → keep; measure again what the flags cost and decide about lazy flags
    from that
  - Above 280 billion → the sorting out is not where the 33 are; compare the disassembly of the
    TEST and XOR executors
  - A test fails or the guest instruction count changes → a flag differs for some operand
    (carry or overflow at the edges, a shift count of 31, the parity of a result); the trace
    tests name the instruction
- **Cut-off**: The same day. `tools/difftest.sh` at 51 of 51, test386 byte for byte, the boot at
  1,651,240,001 instructions; `u_short` extended so that each new executor runs with operands
  that set and clear every flag.

### Result

2026-11-14. **Held in kind, short in amount: 288.8 billion host instructions on the boot, where
the card said below 280 (it was 299.2).** Per instruction it did what was expected:

| Instruction | Before | After |
|---|---:|---:|
| `mov eax, edx` (for reference) | 82 | 82 |
| `test eax, edx` | 101 | 98 |
| `xor eax, edx` | 134 | 105 |
| `cmp eax, edx` | 133 | 108 |
| `add eax, edx` | 132 | 116 |
| `add eax, 5` | 123 | 112 |
| `inc eax` | 107 | 103 |
| `shl eax, 3` | 175 | 114 |
| `dec ecx` and `jnz`, averaged | 111 | 105 |

| Benchmark | Before | After |
|---|---:|---:|
| Linux boot to the shell prompt | 299.2 billion host instructions, 56.8 billion cycles | 288.8 billion, 55.4 to 56.3 billion |
| test386 | 22.7 billion | 22.5 billion |
| bench.bin (real mode) | 97.3 billion, 14.2 billion cycles | 96.7 billion, 14.0 billion |

The machine was busy during these runs, so times are left out; cycles vary by a couple of
percent between runs and the instruction counts do not. The boot still takes 1,651,240,001
guest instructions; `tools/difftest.sh` is at 53 of 53; test386 is byte for byte the reference.

What went in: an executor per operation for the arithmetic grid, `83` and `81` (all but ADC and
SBB, which read the carry and stay general); one each for SHL, SHR and SAR by a count from 1 to
31; conditional jumps as "any of these flags set", "SF differs from OF", and "that, or zero",
with the sense kept in the entry; and the parity flag from a 256-entry table instead of five
shifts and exclusive-ors.

Why 10 billion and not 19: the estimate took 30 off every arithmetic instruction. XOR and CMP
lost 25 to 29, ADD lost 16, the immediate forms 11. The arithmetic flags proper (carry, overflow,
auxiliary carry) cost more than the card allowed for: ADD is 116 where XOR is 105.

**The new tests were wrong twice before they were right.** A test for the new executors
(`u_short2`) matched rustx86 at once. So did two builds with a deliberate error in them: a shift
by 1 with the wrong OF, and JLE without its zero test.

- The shifts by 1 were never run by the new executor: the assembler encodes `shl eax, 1` as `D1`,
  and the executor is for `C1`. They are written as bytes now
- The condition codes were tested with an INC as the instruction to jump over or not, and INC
  sets the flags. From the second condition on, the flags were INC's. The instruction is an LEA
  now, and the conditions have a test of their own (`u_cond`: sixteen conditions from five flag
  states, four passes, 535 lines)

After that both wrong builds fail, each in the third pass, where the executors start. Without
the deliberate errors there would have been two tests that passed and checked nothing; the same
thing happened in E020. A test of a fast path is not finished until a wrong fast path fails it.

What the flags cost now: a logical operation 16 to 23 over a MOV, an addition 34. Lazy flags
would take most of that for the instructions whose flags are never read, at the price named in
the card. Not decided.

## E023: What a run repeats for every instruction and need not (2026-11-14)

- **Hypothesis**: Inside a run of short instructions a NOP costs 74 host instructions, and none
  of them is the NOP. Read from the disassembly of `exec_short` (E021): about 12 to test that the
  instruction can be looked up (the code page, the segment limit), 12 to find the entry and its
  kind, 12 to compare the instruction's bytes, 11 to take the entry apart (copy the decode state,
  note the instruction pointer, the interrupt shadow), 9 to dispatch, 14 after the executor (the
  time, the two saved fields). Several of these do not change from one instruction of a run to
  the next and are redone each time: the code segment's base and limit, the interrupt shadow
  (only the first instruction of a run can have one), the copy of the decode state (a short
  instruction has no prefix, so nothing in it is needed but the opcode, and only by some kinds),
  how much virtual time is left before the run must stop. Taking those out of the loop should
  remove 10 to 15 of the 74: more than 15 billion of the boot's 289 billion host instructions.
- **What changed since last time**: The roadmap called this "execute in blocks": remember a run
  of instructions as a unit and validate it once. That is a new structure with its own
  invalidation. This is the part of it that needs no new structure: the loop stays one
  instruction at a time and each instruction's bytes are still compared; only the work that is
  provably the same for every instruction of a run moves in front of the loop.
- **Next move for each result**:
  - The count falls by the estimate → keep; what is then left per instruction is the lookup,
    the byte comparison and the dispatch, which is what a block structure would remove; decide
    on that with the new numbers
  - It falls by much less → the C compiler was already hoisting these; nothing to do here, go
    to the block structure or stop
  - The guest instruction count changes → something taken out of the loop does change within a
    run after all (the code segment cannot; the shadow and the time are the ones to check)
- **Cut-off**: The same day. `tools/difftest.sh` at 53 of 53, test386 byte for byte, the boot at
  1,651,240,001 instructions.

### Result

2026-11-14. **Held: 277.1 billion host instructions on the boot, from 288.8; the estimate was
"more than 15 billion", and it is 11.7.**

| Instruction | Before | After |
|---|---:|---:|
| `nop` | 74 | 69 |
| `mov eax, edx` | 82 | 78 |
| `mov eax, [ebx+8]` | 162 | 141 |
| `mov [ebx+8], eax` | 149 | 137 |
| `add eax, edx` | 116 | 111 |
| `lea eax, [ebx+edx*4+8]` | 108 | 101 |
| `dec ecx` and `jnz`, averaged | 105 | 98 |

| Benchmark | Before | After |
|---|---:|---:|
| Linux boot to the shell prompt | 288.8 billion host instructions, about 55.4 to 56.3 billion cycles | 277.1 billion, 55.0 billion |
| test386 | 22.5 billion | 22.4 billion |
| bench.bin (real mode) | 96.7 billion | 96.8 billion |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 53 of 53;
test386 is byte for byte the reference. The machine was busy (load about 4), so no times.

What moved out of the loop: the code segment's base and limit; the interrupt shadow, read once;
the virtual time left, as a count kept in the function; and the copy of the decode state, which
a short executor no longer needs at all. It took the opcode from that copy, and now takes it
from the entry in the few kinds that want it. The copy had one more reader, which was the one
to be careful about: the effective address asked the decode state for a segment override. A
short instruction has no prefix, so it has none; the short executors now build their address
with a function of their own that does not ask. That is also why a memory operand got 12 to 21
cheaper, more than the fixed cost did.

The instruction count fell by 4% and the cycle count by about 1%: this was work the host did in
parallel with what the instruction was waiting for anyway.

What is left of the 69 for a NOP: finding the entry (about 12), comparing its bytes (12), the
page and limit tests (10), taking the entry apart (7), the dispatch (8), and the 12 after the
executor. The byte comparison is the one a different design would remove: remember that a page
of code has not been written to since its entries were checked, instead of checking each entry
each time. That needs every store to memory to tell the cache about it, and a missed one would
run stale code; it is the next card or none.

## E024: What v86, VirtualBox and rustx86 do that g86m does not (2026-11-15)

Not an experiment with one hypothesis but a survey, at the owner's suggestion, to find the next
ones. Three sources: rustx86's design records and source (read here); v86's Rust core at commit
315b2b0; VirtualBox's software CPU (IEM, with its threaded recompiler) from the trunk of the
GitHub mirror. The last two were read by separate research passes with file and function names
for each claim; nothing in them was measured. One thing was measured on g86m on the way and is
kept; one was tried and is not.

### Kept: a decode cache sixteen times the size

Counting what still takes the general path on a Linux boot gave 12.6% of all instructions, and
the list was led by instructions that *have* short executors (`89`, `8B`, `8D`, `31`, `E8`,
`C3`, `55`). They were being lost, not missing. The cache was 8,192 entries per code size,
indexed by the low bits of the address; a kernel and a userland do not fit.

| Entries per code size | Host instructions on the boot | Cycles |
|---:|---:|---:|
| 8,192 (was) | 277.1 billion | 55.3 billion |
| 32,768 | 257.9 billion | 51.3 billion |
| 131,072 (now) | 250.4 billion | 49.0 to 49.3 billion |
| 262,144 | 248.7 billion | 49.4 billion |
| 524,288 | 247.5 billion | 49.1 billion |

It levels off at 131,072, which costs 10 MB. 11% fewer cycles for one constant; the boot still
takes 1,651,240,001 guest instructions, `tools/difftest.sh` is at 53 of 53, test386 and the
16-bit benchmark are unchanged. rustx86's cache has 131,072 entries, and its records say a
sweep of that number was a wash there: it had been large from the start.

With the larger cache the general path takes 7.2% of instructions (118.6 million), of which
only 10.5 million are misses or instructions too near a page end; the rest are instructions
with no short executor.

### Tried, not kept: a run that goes on into another page of code

A run ended whenever the next instruction was on a page other than the one last translated,
and the general path ran that instruction (26.6 million times in a boot). Translating the new
page inside the run instead: 257.0 to 257.2 billion host instructions against 250.3 to 250.8,
and cycles within the run-to-run spread (48.5 to 49.7 billion against 49.0 to 50.9). More
instructions and no fewer cycles. Why it is more instructions was not found. rustx86's records
list the same idea among its washes.

### What the other three do

| | g86m | rustx86 | v86 | VirtualBox IEM |
|---|---|---|---|---|
| Unit of execution | one instruction, from a cache of decoded instructions; runs of them without returning | the same, plus chaining of blocks, plus a JIT | one instruction, decoded every time; a JIT to WebAssembly for hot pages | a block of pre-decoded entries (threaded recompiler); a native recompiler above it |
| Is the cached code still valid? | compare the instruction's first eight bytes, every time | a generation number per physical page, bumped by writes to pages that hold code | (JIT) a "has code" bit in the TLB entry, tested by writes | a copy of the block's bytes, compared at block entry, at branch targets and at page crossings |
| Arithmetic flags | computed at once | lazy | lazy: operand, result and size are stored, flags derived when read | computed at once (through the host's own flags) |
| Data TLB | 256 entries per kind of access and privilege mode, tagged | tagged, plus an optional mapping through the host MMU | one untagged entry for each of the million pages, permission bits in the entry, no split by mode | 256 or 8,192 tagged entries; a flush is an increment of a revision that is part of the tag |
| Segment check on a data access | attributes and limit, each time | each time, or folded into a decoded operand | none (base only) | none in "flat" variants, chosen from a precomputed mode word |
| State saved for a fault | instruction pointer and flags (in a run) | the whole CPU, only for instructions that touch memory | the instruction pointer; handlers write registers last | nothing; handlers advance the instruction pointer last, and a longjmp leaves |
| Checking for interrupts | at a deadline in virtual time worked out beforehand | at a countdown to the next timer tick | about every 100,000 instructions, and after STI, POPF, IRET | every 32 instructions in a block, and after instructions that can enable them |
| Read-modify-write on memory | two accesses | - | one translation for both | one mapping for both |
| Repeated string instructions | a page at a time (E020) | a page at a time | a page at a time, MOVS by memcpy | a page at a time, element by element |

### What rustx86 learned that changes how to measure

Its record of closing its optimisation phase (ADR-0015) gives four rules from 26 measured
experiments. In short: bookkeeping that nothing waits for is free on an out-of-order CPU, so
removing it shows in the instruction count and not in the time; removing parallel work saves
at most the longest strand; and what pays is shortening the chain of dependent work that the
*next* guest instruction waits on. Its losses include a larger cache, two levels of TLB, fewer
generation checks, fusing compare with jump, and chaining across pages; its wins include
linking blocks (43%) and the step it calls batch1 (8%).

E023 here is an instance: 4% fewer host instructions, 1% fewer cycles. So is this entry's
second item. **From now on the cycle count decides, with the instruction count as the
reproducible check that nothing else changed.** Cycles vary by about 2% between runs on a busy
machine, so a change under that needs several alternating runs or an idle machine.

### Candidates, in the order this suggests

1. **Executors for what still takes the general path** (7.2% of instructions, each about 250
   host instructions where a short one costs about 100). Measured list, largest first: a
   segment-override prefix on `8B`, `89` and `8D` (per-CPU data through FS), `FF` (indirect
   call and jump, push), two-byte opcodes without an executor (MOVSX, CMOVcc, the bit tests),
   `F7`, `F3 90` (PAUSE), `D1`, `C7`, `3C`, the string instructions without REP. rustx86
   measured its own version of this: 1.1% of instructions, 6% of the time
2. **Blocks**: remember a straight run of instructions as one array of entries, check its bytes
   once, and step from entry to entry without computing an address, finding a slot and
   comparing a tag for each. This is the item that shortens what the next instruction waits on:
   today that chain is instruction pointer, slot, entry, kind, jump. VirtualBox's threaded
   blocks and rustx86's linking are both this
3. **One access for read-modify-write** (`add [mem], reg` costs 240 host instructions where a
   read costs 141)
4. **A mode word with a "flat" bit**, worked out when a segment register is loaded, so that an
   access tests one bit instead of a segment's attributes and limit
5. **Lazy flags**: v86's form is four stores per arithmetic instruction. By rustx86's rules the
   flags of an instruction are mostly work nothing waits for, except by the jump that follows
   a compare; expected to show less in cycles than in instructions

## E025: Short executors for what still takes the general path (2026-11-15)

- **Hypothesis**: With the larger cache, 8.35% of a Linux boot's instructions still take the
  general path, which costs about 250 host instructions where a short executor costs about 100,
  and which ends a run. Counted (share of all instructions): accesses through a segment override,
  which the short executors refuse, about 1.7% (the kernel's per-CPU data through FS:
  `inc`/`dec [fs:..]`, `mov r32, [fs:..]`); instructions with no executor: `not` 0.46%, `rdtsc`
  0.42%, `pause` 0.41%, 16-bit `mov` with an operand-size prefix 0.63%, shifts by one (`D1`)
  0.25%, the AL/EAX-with-immediate forms about 0.4%, `mov r/m, imm` 0.29%, `rep ret` 0.20%; and
  every cached instruction's first two executions, of which the second is avoidable (about 1%).
  Covering these takes about 5% of instructions off the general path, and should take the boot's
  cycles down by more than 5% (49.2 billion now).
- **What changed since last time**: E024 adopted the cycle count as the measure. This is the
  first change judged by it: each step is kept only if the boot's cycles fall over alternating
  runs against the build before it, with the instruction count as the check that the guest saw
  nothing different. The design change that admits segment overrides: the segment an operand
  uses is resolved when the instruction is classified and kept in the entry, as rustx86 does.
- **Next move for each result**:
  - Cycles fall by 5% or more → keep; count the general path again; what is left decides
    whether blocks (E024's second item) are next
  - They fall by less, or not at all, while the instruction count falls → the general path's
    cost is work the host overlaps (rustx86's first rule); stop adding executors and go to blocks
  - A test fails, or the guest instruction count changes → a segment resolved wrongly, or an
    executor that differs from the general code; the new trace test names the instruction
- **Cut-off**: The same day. `tools/difftest.sh` all passing, test386 byte for byte, the boot at
  1,651,240,001 instructions; a trace test that runs each new executor four times, with a
  segment whose base is not zero, and fails against a deliberately wrong build.

### Result

2026-11-15. **Kept, at 3% where the card said 5%.** Boot cycles, three alternating runs each:
48.89, 49.02, 49.18 billion before; 47.50, 47.55, 48.02 after. Host instructions 250.4 to 247.3
billion. The general path now takes 3.79% of the boot's instructions, from 8.35%.

| Benchmark | Before | After |
|---|---:|---:|
| Linux boot to the shell prompt | 250.4 billion host instructions, 49.0 billion cycles | 247.3 billion, 47.7 billion |
| test386 | 22.4 billion, 3.62 billion cycles | 20.5 billion, 3.30 billion |
| bench.bin (real mode) | 96.8 billion, 14.15 billion cycles | 96.7 billion, 14.14 billion |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 56 of 56;
test386 is byte for byte the reference.

What went in:

- **Segment overrides.** The segment an operand uses is resolved when the instruction is
  classified and kept in the top bits of the entry, so the executors look it up the same way
  for an override as without one. The instruction's length is now kept as length minus one in
  three bits to make room
- **Thirteen executors**: INC and DEC on memory, NOT, NEG, MOV of an immediate to memory (32 and
  8 bits), MOV with an operand-size prefix (both directions), the eAX and AL forms with an
  immediate, TEST of eAX and AL with an immediate, RDTSC; and shifts by one (`D1`) through the
  executors the shifts by a count already had; REP on RET and NOP is accepted
- **The second meeting runs short.** An instruction met for the second time is classified
  inside the run and run by its executor at once, instead of a second time by the general path

The cycles fell by more than the instruction count (3% against 1.2%): a general-path
instruction also ends a run, and that is where its cost is, rustx86's observation as well. But
the card asked for 5%, and its branch for less says to stop adding executors and go to blocks.
What remains on the general path is mostly the first meeting of each instruction (`8D`, `89`,
`8B`, `E8`, `C3`, `55`: about 1%), REP MOVSD (0.48%, already a page at a time inside), LODSB and
SCASB without REP (0.33%), and a RET and a JMP with a prefix that is not a segment override or
F3 (0.30% together; not identified).

**The tests, again, needed a deliberately wrong build to be right.** The trace test for the new
executors (`u_short3`, with FS based at 1000h so that an ignored override shows) matched rustx86
at once and caught three of four wrong builds. The fourth, a 16-bit store that wrote 32 bits,
passed: nothing read the two bytes after the store. The test now fills the word first and reads
it back. The self-check for RDTSC (`s_rdtsc`) at first compared two readings within a pass,
which a counter off by one in the executor leaves unchanged; it now also compares the distance
between passes, the first of which is the general path, and the wrong build fails it.

## E026: The instruction pointer goes through memory between two instructions of a run (2026-11-15)

- **Hypothesis**: What a run costs per instruction is not its host instructions but one chain of
  dependent work from each guest instruction to the next, about 20 cycles long, and the body of
  the instruction hangs off it in parallel. Measured on main with `probe/bench32.asm` (per
  iteration of BODY, DEC, JNZ; the empty loop is 224.8 host instructions and 54.6 cycles):

  | BODY | Host instructions added | Cycles added |
  |---|---:|---:|
  | `nop` | 83 | 20.6 |
  | `mov eax, edx` | 90 | 17.7 |
  | `add eax, edx` | 123 | 20.8 |
  | `mov eax, [ebx+8]` | 149 | 19.9 |
  | `add [ebx+8], eax` | 223 | 27.2 |
  | `call fn` (with its RET) | 273 | 32.6 |

  A NOP and a load cost the same 20 cycles at 83 and 149 instructions. The chain, read off
  `exec_short`: load `cpu.ip` (just stored by the instruction before, so forwarded from the
  store), add the base, find the slot, load the entry's length, add, store `cpu.ip`; a jump
  loads, adds and stores it once more. Keeping the instruction pointer in a local for the whole
  run, with `cpu.ip` only stored (for a fault and for the end of the run), takes the two
  store-to-load steps out of the chain. Expected: several cycles off every line of the table,
  and the Linux boot's 47.7 billion cycles down by 10% or more.
- **What changed since last time**: E024's fifth-column reading ("blocks shorten what the next
  instruction waits on") was a guess about where the chain is. The table above is the first
  measurement that separates the chain from the body, and it points at something much smaller
  than blocks to try first.
- **Next move for each result**:
  - The NOP line falls by 4 cycles or more and the boot's cycles fall → keep. The chain is
    where the table says. What is left of it is slot → load of the entry → next slot, which is
    exactly what a block of consecutive entries removes: blocks next, with a number to expect
  - No line falls → forwarding from a store costs this host nothing, or the compiler already
    kept the pointer in a register; read the generated code for the loop and find what the 20
    cycles are (the dispatch jump mispredicted, the virtual time, the flags) before anything
    is built
  - A test fails or the boot's guest instruction count changes → an executor read `cpu.ip`
    where it now has to take the local (CALL pushes it; a fault restores it)
- **Cut-off**: The same day. `tools/difftest.sh` 56 of 56, test386 byte for byte, the boot at
  1,651,240,001 instructions; cycles by three alternating runs against main.

### Result

2026-11-15. **The hypothesis held: about 10% fewer cycles on the boot, with more host
instructions, not fewer.** `probe/bench32.asm`, cycles per iteration (host instructions are the
same to within 3 on every line):

| BODY | main | With the pointer in a local |
|---|---:|---:|
| (empty: DEC, JNZ) | 52.2 | 38.9 |
| `nop` | 75.4 | 54.7 |
| `mov eax, edx` | 73.2 | 53.8 |
| `add eax, edx` | 75.9 | 58.4 |
| `mov eax, [ebx+8]` | 75.5 | 59.2 |
| `add [ebx+8], eax` | 81.9 | 69.4 |
| `call fn` | 89.5 | 78.7 |

| Benchmark | main | Now |
|---|---:|---:|
| Linux boot to the shell prompt, three alternating runs | 48.12, 48.10, 47.61 billion cycles; 247.3 billion host instructions | 43.26, 42.95, 43.03; 249.2 billion |
| test386 | 3.30 billion cycles | 3.14 billion |
| bench.bin (real mode, does not use runs) | 14.18 billion cycles | 14.30 billion |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 56 of 56;
test386 is byte for byte the reference.

The change is a dozen lines: `run_short` returns where the next instruction begins as well as
storing it, and `exec_short` carries that in a local from one instruction to the next. The boot
runs 0.8% *more* host instructions and takes 10% fewer cycles, which is rustx86's rule seen
from the other side: what was removed is waiting, not work.

What this says about the next step. A guest instruction in a run now costs about 16 to 20
cycles for 83 to 150 host instructions, five or more instructions a cycle, so the body is no
longer hanging idle off a long chain. Before building blocks, the same measurement has to say
whether what is left is a chain (slot, load of the entry, next slot; the virtual time, which
is also a global stored and loaded every time; the flags from one instruction to a jump) or
the host's width, in which case it is host instructions that count again.

## E027: What a run still waits on: the virtual time, then the entry (2026-11-15)

- **Hypothesis**: After E026 a NOP in a run costs 15.8 cycles for 83 host instructions, where
  the host's width alone would allow about 10; a load costs 20.3 for 149 and `add [mem], reg`
  30.5 for 223, so cycles now rise with instructions, on top of a floor that is still a chain.
  Two candidates for the floor, read off `exec_short`. (a) `vtime += 1`: a global loaded, added
  to and stored for every instruction, the same shape as `cpu.ip` was, though nothing else in
  the instruction waits for it. (b) instruction pointer → slot → load of the entry's length →
  next instruction pointer, which is in every instruction's way. Counting the virtual time in a
  local and only storing the global removes (a) without changing what any reader of `vtime`
  sees. If the NOP line falls, (a) was on the floor; if it does not, the floor is (b).
- **What changed since last time**: E026 took out the instruction pointer's trip through
  memory. This takes out the second, and only the second, global that a run stores and loads
  each time, so the result separates (a) from (b).
- **Next move for each result**:
  - The NOP line falls by 2 cycles or more → keep; measure again, and go on to (b) with what
    is left as the number to beat
  - It does not fall → keep the change only if the boot's cycles fall at all (they are
    reproducible to 1%); the floor is (b), and the next card is a block of consecutive
    entries, to be judged against 15.8 cycles for a NOP
  - The guest instruction count changes → something read `vtime` between the store and where
    it used to be (RDTSC's executor, a fault)
- **Cut-off**: The same day; the checks of E026.

### Result

2026-11-15. **The NOP line did not fall: the virtual time is not on the floor. Kept all the
same, for the instructions.** `probe/bench32.asm`: a NOP 54.1 cycles per iteration against 53.8,
the other lines within 1.5 either way. Linux boot, three alternating runs: 43.28, 43.10, 42.90
billion cycles before; 42.83, 43.14, 43.00 after; host instructions 249.2 to 248.0 billion
(the compiler no longer reloads the global). Guest instructions 1,651,240,001.

So the floor is (b), and the generated code for the loop shows how long it is: from the
instruction pointer, add the base, mask to a slot, **multiply by 40** (the size of an entry) to
address it, load the entry's operand word, extract three bits, add twice. About 14 cycles of
the 15.8, and the entries sit at an odd address, 40 bytes apart, so the load often straddles
two cache lines.

## E028: The next instruction's address in an array of its own (2026-11-15)

- **Hypothesis**: The chain E027 found is slot → entry → length → next slot, about 14 cycles,
  and most of it is not the load but getting to it and away from it: a multiply by 40, an
  extract and two adds. Keep, for each slot, the linear address of the instruction after it in
  a separate array of 32-bit numbers, and carry the linear address (not the instruction
  pointer) through the run. The chain becomes: mask, load indexed by four bytes, and for a
  taken jump one add; 6 or 7 cycles. This is what a block of consecutive entries would give
  (the next entry without computing where it is from what this one holds) for one array and
  no new notion of validity: the number is used only after the entry's tag and bytes have
  matched, as now. Expected: a NOP from 15.8 cycles towards the 10 or 11 that 83 instructions
  need at this host's width, and the boot's 43.0 billion cycles down by 10% or more.
- **What changed since last time**: E027 ruled out the virtual time and read the chain off the
  generated code. This changes only how the next address is found, not what an entry is.
- **Next move for each result**:
  - A NOP falls to 12 cycles or less → keep. A run is then bound by the host's width, and
    what counts from here is host instructions per guest instruction again (the run loop's
    own checks, the memory path, the flags); blocks are not needed for the chain
  - It falls by less than 2 → the load itself, or the dispatch jump, is the floor; count
    mispredicted branches on the micro-benchmark before anything else
  - The guest instruction count changes → the address after a jump or a RET was formed
    wrongly, or a stale number was used before its entry was checked
- **Cut-off**: The same day; the checks of E026.

### Result

2026-11-15. **Kept: a NOP at 10.7 cycles, and 8% fewer cycles on the boot.**
`probe/bench32.asm`, cycles per iteration, host instructions unchanged:

| BODY | Before (E027) | Now | Per instruction of BODY, now |
|---|---:|---:|---:|
| (empty: DEC, JNZ) | 38.9 | 32.4 | |
| `nop` | 54.8 | 43.1 | 10.7 cycles for 82 instructions |
| `mov eax, edx` | 53.9 | 43.4 | 11.0 for 91 |
| `add eax, edx` | 58.4 | 49.2 | 16.8 for 124 |
| `mov eax, [ebx+8]` | 58.6 | 51.0 | 18.6 for 150 |
| `add [ebx+8], eax` | 69.1 | 64.2 | 31.8 for 228 |
| `call fn` | 76.1 | 74.1 | 41.7 for 275 |

| Benchmark | Before | Now |
|---|---:|---:|
| Linux boot to the shell prompt, three alternating runs | 43.27, 42.96, 43.17 billion cycles; 248.1 billion host instructions | 39.69, 40.01, 39.59; 246.6 billion |
| test386 | 3.14 billion cycles | 3.08 billion |
| bench.bin (real mode) | 14.07 billion cycles | 14.08 billion |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 58 of 58;
test386 is byte for byte the reference. Since the morning's main (E025) the boot has gone from
47.7 to 39.8 billion cycles, 17%, on a host instruction count that moved by 0.3%.

A NOP is at the 12 the card asked for, so by its first branch a run of simple instructions is
now bound by how many host instructions there are, and the table says where they are dear: the
lines with flags or memory did not fall as far as the NOP, and `add [mem], reg` and CALL hardly
fell at all. Those have chains of their own inside the instruction (the flags stored and read
back; a memory operand read, then written, with a translation each time; the stack pointer),
and they are next: one access for read-modify-write (E024's third candidate), and the path
from an ALU result to the stored flags.

**A trace test cannot test this, and the first test written for it did not.** With a code
segment based at 100h, four wrong builds were tried: three were caught by test386, and a RET
that forgets to add the base to the address it carries was caught by nothing. The trace test
written for it passed the wrong build too, because tracing stops after every instruction and
then nothing is carried from one to the next. The check is now a self-check, `s_csbase`,
which runs untraced: a RET in the based segment to an offset whose linear address, without the
base, holds an instruction the cache already knows. The wrong build fails it.

## E029: The run loop's own host instructions (2026-11-15)

- **Hypothesis**: After E028 every line of the micro-benchmark runs at seven to eight host
  instructions a cycle, the host's width, so cycles now follow host instructions. A NOP costs
  82 of them, all of it the loop: at 1.65 billion guest instructions that is about 130 of the
  boot's 247 billion, more than the instructions' own work. Read off the generated code, the
  loop does these for every instruction and need not: (1) reloads the code page's number, its
  "in RAM" flag and its physical address, and tests page, flag and offset separately, though
  no short executor can change them; (2) tests "interrupts were held off" and "no time left"
  separately; (3) stores `light_save` every time; (4) dispatches through two jump tables with
  a range test each, because the kind numbers have gaps. Removing these takes about 12 of the
  82, and the boot's host instructions and cycles down by about 5%.
- **What changed since last time**: E026 to E028 shortened what an instruction waits for and
  left the instruction count alone. This is the first step on the other side, and it tests
  the claim that cycles now follow instructions.
- **Next move for each result**:
  - Instructions and cycles both fall by about the same share → keep; the claim holds, and the
    next cards go after the largest counts: validating an entry (tag, kind, eight code bytes:
    about 20 a time), then the memory path and the flags
  - Instructions fall and cycles do not → the loop is still waiting on something; back to
    reading chains (the code bytes' load and compare are the first suspect)
  - The guest instruction count changes → one of the hoisted values does change within a run
- **Cut-off**: The same day; the checks of E026, 58 of 58.

### Result

2026-11-15. **Kept: 7% fewer host instructions and 5% fewer cycles on the boot.** The first
branch of the card, near enough: cycles follow instructions now, at about three quarters of
the share.

| Benchmark | Before | Now |
|---|---:|---:|
| Linux boot to the shell prompt, three alternating runs | 246.6 billion host instructions; 39.59, 39.53, 39.48 billion cycles | 229.6 billion; 37.42, 37.47, 37.39 |
| test386 | 20.44 billion; 3.08 billion cycles | 19.76 billion; 2.99 billion |
| bench.bin (real mode) | 97.16 billion; 14.13 billion cycles | 96.79 billion; 14.10 billion |

`probe/bench32.asm`, per instruction of BODY: a NOP 82 host instructions to 71, 10.7 cycles to
9.9; `mov eax, [ebx+8]` 150 to 141, 18.6 to 16.0; `add [ebx+8], eax` 228 to 215, 31.8 to 28.2;
`call fn` with its RET 275 to 255, 41.7 to 39.3. The boot still takes 1,651,240,001 guest
instructions; `tools/difftest.sh` is at 58 of 58; test386 is byte for byte the reference.

What went in, all in `exec_short`: the code page's number, flag and physical address are read
once before the loop, and "same page, not in its last 15 bytes" is one comparison of the
offset from the page's start; "interrupts held off for the first instruction" is folded into
the time left (a run of one); `light_save` is set once on entry and cleared on the two ways
out; and the unused kind numbers are named in the `match`, which makes the dispatch one jump
table.

A NOP is still 71 host instructions. What they are now, from the generated code: finding and
validating the entry (slot, tag, kind, the eight code bytes fetched with a range test and
compared under the mask) about 25; loading the entry's fields, storing `cpu.ip`, and the
dispatch about 15; the tail (time left, virtual time, the saved instruction pointer and
flags, the next offset and limit tests) about 20.

## E030: Validating an entry in fewer host instructions (2026-11-15)

- **Hypothesis**: Of the 71 host instructions a NOP costs in a run, about 25 find and validate
  its entry, and four pieces of that are bookkeeping the loop can do once or not at all:
  (1) the range test around the fetch of the eight code bytes, which holds for every offset
  once the page is known to be in RAM; (2) "no executor" and "not classified yet" as two tests
  of the kind, then a third inside the dispatch for the range of the jump table: one test for
  "is this a kind with an executor" can do for all three; (3) the test of the instruction
  pointer against the segment limit, which for a given page is a bound on the offset in the
  page, like the page test itself; (4) the multiply by 40 to address the entry: an entry of 64
  bytes is addressed by a shift. Together about 14 of the 71, and by E029's ratio the boot
  loses about 6% of its host instructions and 4% of its cycles.
- **What changed since last time**: E029 took what was plainly repeated. These four need the
  compiler to see something (a range, a single test), so each is checked in the generated
  code and by the instruction count of a NOP, one at a time.
- **Next move for each result**:
  - A piece lowers the NOP's count → keep it. Then the body: the memory path and the flags
  - A piece does not lower it (the compiler does not see it) → take it out; say so
  - 64-byte entries lower the count but raise the boot's cycles (more cache per instruction)
    → keep 40
  - The guest instruction count changes → the limit folded into the offset bound is wrong at
    a page that straddles the limit; that case must take the general path
- **Cut-off**: The same day; the checks of E026, 58 of 58.

### Result

2026-11-15. **Kept for the instructions; the cycles did not follow, which is the finding.**
Pieces (1) to (3) went in together; (4), the 64-byte entry, was not tried, because of what the
first three showed.

| | Before | With (1) to (3) |
|---|---:|---:|
| A NOP in a run | 72 host instructions, 10 cycles | 59, 10 |
| Linux boot, host instructions | 229.6 billion | 211.8 billion (7.8% fewer) |
| Linux boot, cycles, three alternating runs | 37.62, 37.74, 37.65 billion | 36.90, 36.73, 37.96 (about 1% fewer) |

The compiler did see all three: the range test around the code bytes is gone once the page's
address is tested against RAM before the loop and the index is formed by adding in 64 bits;
one test of `kind - 1` against the last kind replaces three; the limit is a bound on the
offset. The guest instruction count is unchanged; `tools/difftest.sh` is at 60 of 60 with the
new self-check described under E031; test386 is byte for byte the reference (19.79 to 19.40
billion host instructions, 3.03 to 3.00 billion cycles); bench.bin is unchanged.

But E029 lost 7% of the instructions and 5% of the cycles, and this loses 8% and 1%. By the
card's reading of E029 ("instructions fall and cycles do not → the loop is still waiting on
something") there is a chain again, and it is not the one E028 cut: a NOP's 10 cycles are
unchanged at 59 instructions, and DEC with JNZ costs 16 each.

## E031: A conditional jump that waits for its flags (2026-11-15)

- **Hypothesis**: In a run, a conditional jump is `if condition { next += offset }`, and the
  compiler turns that into a conditional select, not a branch. A select is data: the address
  of the instruction after the jump then depends on the flags, the flags on the instruction
  that set them, and that instruction on its operands and its own entry. So across every
  conditional jump the host can start nothing of what follows until the compare before it is
  done, where a branch would have been predicted and run ahead. That is the whole body of an
  instruction, with two trips through memory for the flags, on the chain: about 30 cycles for
  the benchmark's DEC and JNZ, which is what the empty loop costs (32). Making the taken path
  something the compiler cannot fold into a select (a store to a variable that is not stored
  otherwise) forces a branch.
- **What changed since last time**: E030 showed the cycles no longer follow instructions; this
  names the chain and changes one thing, in the four conditional-jump executors.
- **Next move for each result**:
  - The empty loop falls from 32 cycles towards 20, and the boot's cycles fall → keep; then
    look for other selects on the way to the next address (RET's target is a load, which is
    data too, but there is nothing to predict it with short of a return stack)
  - The loop falls and the boot rises → the host mispredicts the one branch all guest jumps
    share more than the select cost; try a branch per condition kind, or leave the select
  - Nothing moves → the compiler already branched, or made a select again: read the code
- **Cut-off**: The same day; the checks of E026, 58 of 58.

### Result

2026-11-15. **Nothing moved; taken out.** With a store on the taken path of the four
conditional-jump executors the empty loop cost 31.1 cycles against 31.3, and the other lines
moved by less than their spread. Whether the compiler had made a branch already was not
settled by reading the code (the loop is laid out in several copies); the measurement says the
jump is not what the loop waits on, either way.

Then the pieces of the loop were taken out one at a time, in builds made only to be timed (the
store of the interrupt shadow, the saved flags, the saved instruction pointer, the virtual
time, the comparison of the code bytes, the tag test): a NOP stayed between 39 and 43 cycles
per iteration in all of them. None of them is the floor.

What the floor is, by elimination and by sixteen of one instruction in a row (per instruction):

| Instruction | Host instructions | Cycles |
|---|---:|---:|
| `nop` | 59 | 10.0 |
| `mov eax, edx` | 68 | 10.3 |
| `inc eax` | 87 | 16.7 |
| `lea eax, [ebx+8]` | 81 | 16.8 |
| `cmp eax, edx` | 94 | 18.6 |
| `mov eax, [ebx+8]` | 129 | 18.9 |
| `add eax, edx` | 101 | 19.5 |
| `add [ebx+8], eax` | 203 | 29.3 |

A NOP at 59 instructions and at 72 (before E030) is 10 cycles: that is the step E028 left,
from this instruction's address to a slot, to a load from `dc_next`, to the next address.
A load whose address comes from the load before it cannot be made shorter by arranging the
array; E028 took it from about 14 cycles to about 10 and that is where it stays while the next
instruction is found *by its address*. This is the measured case for a block of consecutive
entries (E024's second candidate): inside a block the next entry is the one after this one,
known without waiting, and only a taken jump has to look anything up. The floor is 10 of the
22 cycles the boot averages per guest instruction.

The second thing the table shows: `lea`, `inc` and `cmp` cost 6 to 9 cycles more than a NOP
for 20 to 35 more instructions, far more than their share. They have in common that they read
a guest register that the instruction before them wrote (through memory), and INC and CMP
that they write the flags, which are read, changed and stored in memory. That is the body's
own chain, and it is the same shape E026 found for the instruction pointer.

**A hole found on the way, older than this change.** With the limit folded into the offset
bound, a build that ignores the limit passed every test, and so would have a build that ignored
the old limit test: nothing ran a run up to a code segment's limit. `s_cslimit` does (a
segment whose limit ends in the middle of a row of INCs, the ones beyond it made known to the
cache through a flat segment first), and the wrong build fails it. Two versions of the test
passed the wrong build before the third did not: instructions beyond the limit are not in the
cache unless something put them there, and a run is not attempted on a page that begins below
the segment's base.

## E032: The next instruction by position, not by address (2026-11-15)

- **Hypothesis**: What a run waits on is the load from one instruction's address to the next
  (E031: 10 cycles for a NOP, at 59 host instructions or at 72). Keep, beside the cache, an
  array `seq` of slot numbers in the order instructions were executed, and a place in it for
  each slot. A run carries a position `p`; the instruction to run is the one `seq[p]` names,
  and after it `p + 1`. Nothing about `seq[p + 1]` waits for the instruction at `p`: its
  entry, its code bytes and the address after it all come from `p + 1`. Whether it *is* the
  instruction at the address the one before it led to is a comparison (its tag against that
  address), which the host predicts and runs past. When it is not (a taken jump whose target
  is elsewhere in the array, or not in it yet), the slot is found from the address as now and
  the position from the slot, or the instruction is appended; that costs what every
  instruction costs today, once per such jump. This is a block of consecutive entries with no
  notion of a block: the array is only ever a guess, and an entry is used only when its tag
  matches the address, as now, so nothing new can be stale in a way that matters. Expected:
  a NOP from 10 cycles to 8.5 or less (what is left is the host's width: 59 instructions and
  a few more for the array); the boot's cycles down by 5% or more.
- **What changed since last time**: E028 shortened the load on the chain; E031 showed it is
  still the floor and that nothing else in the loop is. This takes the load off the chain for
  instructions that follow one another, at the price of a host branch that now depends on
  where the guest's jumps go.
- **Next move for each result**:
  - A NOP falls to 8.5 or less and the boot's cycles fall → keep. Then what bounds a run is
    the bodies: guest registers and flags that go through memory (E031's second table)
  - A NOP falls and the boot does not, or rises → the comparison is mispredicted where the
    guest's jumps vary; count how often the position is found by address, and try remembering
    a second successor for a jump before giving up
  - A NOP does not fall → the floor is not that load after all; the array comes out, and the
    next thing is a sampling profile of the loop by address, not another guess
  - The guest instruction count changes → an entry was used whose tag did not match
- **Cut-off**: The same day; `tools/difftest.sh` 60 of 60, test386, the boot's count.

### Result

2026-11-15. **Not kept: the boot took 16% more cycles.** And the measurements made to find out
why close the question of blocks.

| | main | With `seq` |
|---|---:|---:|
| Linux boot, host instructions | 211.7 billion | 240.7 billion |
| Linux boot, cycles, two alternating runs | 36.75, 36.49 billion | 42.90, 42.50 |
| `nop`, sixteen in a row, per instruction | 60 instructions, 10.0 cycles | 75, 9.3 |
| `mov eax, edx`, sixteen in a row | 69, 10.3 | 83, 18 |

A NOP fell by 0.7 cycles, not 1.5; everything else rose, and the boot ran 14% more host
instructions: with a taken jump every few instructions, finding the place for the target
(two more loads and often an append) costs more than following the array saves. The guest
instruction count was unchanged. The array is out.

**How much the load on the chain is worth, measured directly.** A build made only to be timed
lets the NOP executor form the next address as "this one plus one", with no load. 250 NOPs in
a row: 10.5 cycles each with the load, 8.6 without (at 64 host instructions, which is the
host's width). So the load from one instruction's address to the next is 2 cycles of the 10,
not the 10 of E031's reading, and no arrangement of entries can win more than that 2: about a
tenth of the boot at the very most, before what the arrangement itself costs. **Blocks are
off the list.** E031 was right that a NOP's time did not follow its instruction count, and
wrong about why: at 72 instructions it was at the width, at 59 it is at the chain, and the two
are 2 cycles apart.

**The sixteen-in-a-row benchmark misleads.** `mov eax, 5` cost 14.7 cycles sixteen in a row,
12.8 four in a row and 11.2 sixty-four in a row. A long row of one kind followed by another
kind is the case a history-based predictor gets wrong at the dispatch jump, and the profile
below shows those samples on the first instruction of the executor. E031's second table (LEA,
INC and CMP "costing 6 to 9 cycles more than a NOP") is that effect, not registers and flags
going through memory; that reading is withdrawn.

**A profile by address** (`probe/prof.c`: a timer signal notes the program counter; an
interrupted CPU reports the oldest instruction it has not finished, so samples pile up on what
was being waited for). The Linux boot, 14,584 samples:

| Where | Share |
|---|---:|
| `exec_short`, the run loop and its executors | 73.4% |
| of which: the loads of the entry and of `dc_next`, the jump-table load, the stores that wait for them | about 28% |
| of which: the first instruction after an unconditional jump (an executor's entry, where a mispredicted dispatch shows) | 11.8% |
| `exec_general` | 10.9% |
| of which: one store, the destination of `mov [mem], imm` on its way through the general path | 3.6% |
| `run_until` | 5.3% |
| of which: the script's search of the serial output for the text it waits for | 3.5% |
| `shift` | 3.0% |
| `string_op` | 1.9% |
| `seg_read_general`, `seg_write_general` | 2.6% |
| `parse_modrm` | 1.2% |

Three things in it that no count of instructions showed. The script that these measurements
are made with searches all of the serial output since the last match, on every poll, for the
text it waits for: 3.5% of every boot figure in this ledger is that search, which is the
harness and not the emulator. A single store in the general path holds 3.6%; the general path
runs instructions met for the first time, whose bytes and operands are memory the host has
not touched lately, so this is the guest's memory missing the host's caches, and it is the
same wherever code is new. And `shift`, the general routine for shifts and rotates that the
executors for a count in CL and for the less common shifts call, is 3%.

## E033: Two things the profile pointed at (2026-11-15)

- **Hypothesis**: Two entries in E032's profile are plain waste and are worth what the profile
  says. (a) The script's wait for a text searches the serial output from the last match to the
  end on every poll: 3.5% of the boot's cycles. Searching only what is new (from where the
  last search ended, less the text's length) finds the same match on the same poll. This is
  the measuring harness, not the emulator: it makes the figures honest and a scripted boot
  faster, and an interactive boot no faster at all. (b) Shifts by CL (`D3`) go through the
  general `shift` routine, a call that works on any width and sets the flags one at a time:
  3.0% of the boot. SHL, SHR and SAR of 32 bits by a count of 1 to 31 have one-step inline
  forms already (the executors for a constant count use them); with the count taken from CL
  the executor can use the same forms, and call `shift` only for a count of zero and for
  rotates. Expected: `shift` falls to under 1% of a profile, and the boot's cycles by about
  2% from (b) and 3% from (a).
- **What changed since last time**: Until E032 the choice of what to do came from counting
  instructions and reading code. These two come from a profile by address.
- **Next move for each result**:
  - Both give about what the profile said → keep; the profile is a good guide to the size of
    things, and the next targets are taken from it in order (the dispatch's mispredictions
    are the largest that is not inherent)
  - (b) gives much less → `shift`'s samples were something waiting inside it (the flags),
    not its length; look at where in it they are
  - The guest instruction count changes → (a) found a match on a different poll, or (b)'s
    flags differ from `shift`'s for some count
- **Cut-off**: The same day; `tools/difftest.sh` 60 of 60 with a deliberately wrong build for
  (b), test386, the boot's count.

### Result

2026-11-15. **Both kept: 4.2% fewer cycles on the scripted boot, of which 3.4% is the harness.**

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| main, three alternating runs | 211.7 billion | 36.63, 36.51, 36.54 billion |
| with (a), the search of only what is new | 205.4 billion | 35.41, 35.26 |
| with (a) and (b), shifts by CL in one step | 202.5 billion | 35.01, 35.05, 34.97 |

(a) gave the 3.4% the profile said (3.5%). (b) gave 0.9% where the profile said `shift` was
3.0%: not "much less", but under half. The routine is still called for rotates, for shifts of
8 and 16 bits and from the general path, and some of its samples will have been the flags it
reads and writes several times over, which the one-step forms do once.

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 60 of 60;
test386 is byte for byte the reference and bench.bin is unchanged (neither uses the script's
search, and neither is heavy in shifts by CL). Three wrong builds of (b) (SAR done as SHR, SHR
as SHL, the count masked to four bits) all fail test386, and the first fails `u_short` too.

**Every boot figure before this entry includes the search**, about 1.2 billion cycles at the
end and more when boots were slower in host time but the same in polls. Comparisons between
two builds measured the same way stand; the absolute figures, and the "cycles per guest
instruction" derived from them, were about 3% high. From here the boot stands at 35.0 billion
cycles and 202.5 billion host instructions: 21.2 cycles and 123 host instructions for each
guest instruction.

Where the day leaves the list. Gone from it: blocks (E032). The largest items of the profile
that are not the guest's own memory: the dispatch jump's mispredictions (about 12% of samples
sit on an executor's first instruction), the general path (11% of the time for 3.8% of the
instructions, part of it cache misses on code met for the first time), and the loads that
every instruction makes of its entry (about 28%, which is where the host's width shows).

## E034: The first instruction on another page of code (2026-11-15)

- **Hypothesis**: The profile (E032) has the general path at 11% of the time for 3.8% of the
  instructions. Counted again by opcode on a boot, with whether the decode cache had the
  instruction: 2.66% of all instructions are listed (those counted 200,000 times or more),
  1.07% with no executor (REP MOVSD 0.47%, LODSB 0.18%, SCASB 0.15%, then small ones) and
  **1.58% that the cache was not even asked about**: `8D` with a segment prefix (the kernel's
  padding), `C3`, `EB`, `8B`, `89`, `55`, `85`, `E8`. Those are instructions that do have
  executors, at the start of a page of code other than the one last translated: a run ends
  there (E024 counted 26.6 million such ends), and the general path then finds the cache
  "not usable", because its test is that the page is the translated one, and decodes the
  instruction from its bytes. Translating the page first (one TLB lookup, which the fetch of
  the first byte would do anyway) makes the cache usable, and the instruction is run by its
  executor from the general path. Expected: about 200 host instructions saved 26 million
  times, 2.5% of the boot's instructions, and 2% or more of its cycles (these instructions
  also touch the bytes of the instruction a second time, which the executor does not).
- **What changed since last time**: E024 tried to keep the *run* going across the page and it
  did not pay. This leaves the run's end where it is and only stops the general path from
  decoding what the cache holds.
- **Next move for each result**:
  - Cycles fall by 2% or more → keep; the count of what is left on the general path then has
    REP MOVSD, LODSB and SCASB at its head, and LODSB and SCASB without REP are two executors
  - They fall by less → the cost of a run's end is elsewhere (the way out of the loop and
    back in); measure a run's end by itself before touching it
  - A test fails or the guest instruction count changes → the translation raised a page
    fault at a different moment than the fetch did (it must come after the checks for a
    pending fault and an interrupt, and not when the instruction pointer is beyond the limit)
- **Cut-off**: The same day; `tools/difftest.sh` 60 of 60, test386, the boot's count.

### Result

2026-11-15. **Kept, at 1.3% where the card said 2% or more.** Linux boot, three alternating
runs: 35.02, 35.03, 34.99 billion cycles before; 34.54, 34.50, 34.69 after; host instructions
202.5 to 199.4 billion (1.5%). The guest instruction count is unchanged.

By the card's second branch the cost of a run's end is elsewhere, so the boot was profiled
again (`probe/prof.c`, three profiles that agree to within a point), and the answer was not a
run's end at all:

| Where | Share |
|---|---:|
| `exec_short` | 68 to 71% |
| `string_op` | 12 to 13% |
| `exec_general` | 10 to 11% |
| `shift` | 2% |
| `run_until` | 2% |

`string_op` was 1.9% in E032's profile. That profile's build laid the code out differently
(the bulk routine was not inlined into it) and its share was spread over two functions; the
figure to trust is this one, three times over. Nine of its twelve points are on one
instruction, a byte store in the per-element path.

## E035: String instructions without REP (2026-11-15)

- **Hypothesis**: Counting the elements that go through `string_op`'s per-element path on a
  boot: 7.7 million MOVSW without REP, 5.3 million SCASB under REPNE, 2.9 million LODSB and
  2.5 million SCASB without REP, 0.55 million CMPSB under REPE. The MOVSW is one loop, found by
  its address and bytes: `66 A5 / 49 / 75 FB`, `movsw; dec ecx; jnz`, the match copy of the
  decompressor that unpacks the kernel (5.9 million) and of the kernel's own that unpacks the
  initramfs (1.8 million), copying two bytes at a time from a few bytes back. Each one takes
  the general path (about 480 host instructions against 100 for an executor, measured with
  `probe/bench32.asm`) and ends a run, so the loop's DEC and JNZ each start a new one. Short
  executors for MOVS (32, 16 and 8 bits), LODSB, SCASB and STOS (8 and 32 bits) without REP,
  either direction, with a segment override for the source, keep such loops inside one run.
  Expected: `string_op` from 12% of a profile to about 3% (what REPNE SCASB and the bulk
  routine leave), and the boot's cycles down by 5% or more.
- **What changed since last time**: E025 listed "LODSB and SCASB without REP (0.33%)" by
  count and left them; the count missed MOVSW because it was read as REP MOVSD (same opcode,
  different prefix), and nothing weighed these by time until the profile.
- **Next move for each result**:
  - Cycles fall by 5% or more → keep. REPNE SCASB (a `strlen`) is then the largest string
    item, and it can scan a page at a time as REP MOVS copies one
  - They fall by much less than the profile's nine points → the store's samples were the
    guest's memory (the copy's destination is fresh memory), not the path; say so
  - A test fails or the guest instruction count changes → direction, the source's segment,
    or what is left changed when the access faults
- **Cut-off**: The same day; a trace test that runs each new executor four times, forwards
  and backwards and through an overridden segment, against rustx86, and fails for
  deliberately wrong builds; `tools/difftest.sh`, test386, the boot's count.

### Result

2026-11-15. **Kept, at about 1.2% where the card said 5% or more: the second branch.** With
E034 the two together, three alternating runs against main: 35.46, 35.41, 35.36 billion cycles
before; 34.28, 34.10, 34.27 after (3.3%); host instructions 202.6 to 195.7 billion (3.4%).
E034 alone had reached 34.5 to 34.7. The guest instruction count is unchanged.

| | main | E034 and E035 |
|---|---:|---:|
| Linux boot, host instructions | 202.6 billion | 195.7 billion |
| Linux boot, cycles | 35.41 billion | 34.22 billion |
| General path, share of guest instructions | 3.8% (E025's count) | 1.42% |
| test386 | 19.28 billion instructions, 2.99 billion cycles | 18.87 billion, 2.94 billion |
| bench.bin (real mode) | 96.9 billion instructions, 14.2 billion cycles | 97.55 billion, 14.28 billion |

`tools/difftest.sh` is at 61 of 61 with the new trace test `u_string`; test386 is byte for
byte the reference. Seven deliberately wrong builds of the new executors: six failed
`u_string` at once; the seventh, MOVSB ignoring a segment override, passed, because the test
read back the four bytes before the one that MOVSB wrote. It reads the right ones now and the
wrong build fails.

**The store is still where the time is.** In a profile of the new build the MOVSW loop's store
(now one 16-bit store in `exec_short`) holds 4.1% of the samples for 7.7 million executions,
about 180 cycles each; in the general path it held 9%, about 400 each. An executor costs 60
cycles in `probe/bench32.asm` with source and destination far apart. So most of what that
loop costs is neither path: the time per copy fell with the number of host instructions per
iteration but stayed several times what those instructions take. The loop copies from a few
bytes behind where it writes. **Not established, the leading guess:** when the distance is
odd, the 16-bit load of one iteration straddles the 16-bit stores of two earlier ones, the
host cannot forward such a load from its store buffer, and the load waits until those stores
have left it, which makes each iteration wait for the one before to be completely done. The
benchmark could not test it: its addresses above 1 MB wrap, with the A20 line off, onto its
own code. A benchmark with A20 on and the distance as a parameter is the first step of the
next card; if the guess holds, the copy has to read its bytes so that each comes from one
earlier store.

**16-bit code paid for E034 at first.** The test "is this another page" ran on every
instruction of the general path, which is every instruction of 16-bit code: bench.bin took 3%
more host instructions and 2.5% more cycles. It is now made for 32-bit code only (16-bit code
does not run in runs, and its first fetch translates the page); bench.bin is at 0.7% more
instructions and the same cycles to within the spread.

A second single store in `exec_general` holds 5% of the samples, in the code for `mov r/m,
imm`, at an address in the decompressor's working memory, and by the counts that instruction
is far too rare there to cost that by running. It is not explained.

## E036: A copy from a few bytes back (2026-11-15)

- **Hypothesis**: E035 left the decompressor's `movsw; dec ecx; jnz` at about 180 cycles a
  copy in the boot where its executor takes 60 with source and destination far apart. The
  guess: the copy reads from a few bytes behind where it writes, and when that distance is
  odd, or 1, each 16-bit load straddles two earlier 16-bit stores; the host cannot forward
  such a load out of its store buffer and makes it wait until both stores have left the
  buffer, which is after everything before them has completed. If so, in
  `probe/bench32.asm` (within the first megabyte, an outer loop setting the pointers again)
  a distance of 1 or 3 costs several times what a distance of 2, 4 or 4096 costs, and the
  fix is in how `seg_read` gets its bytes: a load that can come from the store buffer is one
  that lies inside one earlier store, so a 16-bit read that might straddle is better made as
  two byte loads, each inside one store.
- **What changed since last time**: E035's attempt to measure this wrapped at 1 MB onto its own
  code. This measures first and changes code only if the distances differ.
- **Next move for each result**:
  - Odd distances cost several times even ones → the guess holds; make the read of MOVSW
    (and MOVSD, whose 32-bit load straddles for any distance under 4) byte by byte in the
    executors, measure the same table again, then the boot
  - All distances cost the same → the guess is wrong, and the boot's 180 cycles are the
    guest's memory (the destination is memory the host has not touched); nothing to change
    in the copy; record it and take the next item of the profile
  - Small distances cost more whether odd or even → it is the dependence itself (each copy
    needs the one before); that is the guest's own chain and cannot be shortened below one
    store-to-load step, but byte loads may still shorten that step
- **Cut-off**: The same day.

### Result

2026-11-15. **All distances cost the same: the guess is wrong, and nothing in the copy
changes.** `probe/bench32.asm` with an outer loop (100 times 200,000 copies from 10000h, so it
stays under 1 MB), main, per iteration of the instruction, DEC and JNZ:

| Distance from source to destination | MOVSW | MOVSD |
|---:|---:|---:|
| 4096 | 55.8 cycles | 48.9 |
| 8 | 49.1 | 49.1 |
| 4 | 53.2 | 49.0 |
| 3 | 49.3 | 49.9 |
| 2 | 49.4 | 49.5 |
| 1 | 50.3 | 49.2 |

341 host instructions an iteration in every case. A load that straddles two earlier stores
costs nothing measurable here: by the time the interpreter reaches the next copy, the stores
of the last one have long left the buffer.

**And the "180 cycles a copy" was a misreading of the profile, not a cost of the copy.** By the
card's second branch the suspicion moved to the profiler: are samples drawn to stores into
memory the host is touching for the first time? A profiling build that writes to every page of
guest RAM and of the cache before it starts gave the same picture, so they are not. What the
sampled instruction is, is one 16-bit store into guest RAM that the compiler has merged from
several executors: MOVSW's, but also `mov [mem], r16` and the others that store 16 bits. Its
samples are those of every 16-bit store in the boot, and dividing them by the number of MOVSWs
was the error. The same holds for the single byte load (4.5%), the byte store (3.0%) and the
store in `exec_general` that E035 called unexplained (it is where every write of the general
path's `mov r/m, imm` and its neighbours lands). **A profile by address can say where the host
waits, and cannot say for which guest instruction, wherever the compiler shares code between
executors.** That note is now in `probe/prof.c`.

What the profile does say, with all memory touched beforehand (7,566 samples): `exec_short`
80.5%, `exec_general` 10.3%, `string_op` 2.3%, `shift` 1.8%, `run_until` 1.4%. Inside
`exec_short` the accesses to guest RAM together hold about 15%, the loads of the entry and
the dispatch about 25%.

The day, E026 to E035: the scripted boot from 47.7 to 34.2 billion cycles (28%), 247 to 196
billion host instructions; of that, 3.4 points were the script's own search. What is left on
the list are items of one to two percent each: a "flat" bit so that an access through a flat
segment skips the attribute and limit tests (E024's fourth), one translation for an
instruction that reads and writes the same operand (its third), REPNE SCASB a page at a time.

## E037: One bound per segment for the short access path (2026-11-15)

- **Hypothesis**: `seg_read` and `seg_write` test, on every access, that the segment is valid,
  writable data that grows upward (a load, a mask, a compare), that its limit is at least the
  access's width, and that the offset is within it (a load and two compares), before they look
  in the TLB. All of that depends only on the segment, which changes at four places in the
  source (a descriptor loaded, a null selector, a virtual-8086 load, the Linux loader's set-up)
  and when a fault puts the CPU back. Keep one number per segment, `seg_top`: the first offset
  that may *not* take the short path (the limit less 2, or zero for a segment that never may),
  and the tests become one load and one compare. An access in the last three bytes of a
  segment then takes the general path whatever its width, which is right and slower, and rare.
  About 7 host instructions off each access to memory; by the profile about 15% of the time
  is in those accesses and a guest instruction makes one about every other time: expected
  2 to 3% of the boot's host instructions and 1.5% or more of its cycles.
- **What changed since last time**: E024's fourth candidate, a "flat" bit in a mode word, in
  the form that needs no mode word and serves segments that are not flat as well (real mode's
  64 KB ones, the per-CPU segment).
- **Next move for each result**:
  - Instructions fall by 2% and cycles by 1% or more → keep; next, one translation for an
    instruction that reads and writes the same operand
  - Instructions fall and cycles do not → the access path is not what the accesses' time is
    (the guest's memory is); stop shaving it and say so
  - A test fails, or a build that checks `seg_top` against the limit and attributes at every
    access finds a difference → a place that changes a segment was missed
- **Cut-off**: The same day; a checking build run over `tools/difftest.sh` and a Linux boot;
  a deliberately wrong build (a setter that does not refresh the bound) must fail a test.

### Result

2026-11-15. **Kept: 3.6% fewer host instructions and 1.8% fewer cycles on the boot.**

| | main | With `seg_top` |
|---|---:|---:|
| Linux boot, host instructions | 195.8 billion | 188.7 billion |
| Linux boot, cycles, four alternating runs on a quiet machine | 34.34, 34.16, 34.15, 34.16 billion | 33.56, 33.56, 33.54, 33.62 |
| test386 | 18.87 billion instructions, 2.94 billion cycles | 18.38 billion, 2.91 billion |
| bench.bin (real mode) | 97.60 billion instructions, 14.36 billion cycles | 96.13 billion, 14.10 billion |

(Three earlier alternating runs, with something else running on the host, spread from 33.7 to
35.7 billion for both builds and decided nothing; the instruction counts were the same in all
seven.) The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 63
of 63 with the new self-check; test386 is byte for byte the reference. The 16-bit benchmark
gains as well, since its accesses take the same path.

**How the bound was checked.** A copy of the source in which every access first compares
`seg_top` with what the limit and attributes say, and stops the machine on a difference, ran
the whole of `tools/difftest.sh` and a Linux boot to the prompt without stopping.

**Three wrong builds, and what caught them.** A build in which loading a descriptor does not
refresh the bound, one in which loading a null selector does not, and one in which a fault's
restoring of the CPU does not: all three passed every test there was. The first two are
errors that let an access through that must fault, and nothing tested for that after the
segment register had held something larger. `s_segbound` does (a segment with a limit of FFh
after a flat one; a null selector after a flat one; a read, a write and a read through FS,
four passes), and both wrong builds fail it. The third is not caught by any test: it needs
an instruction that changes a segment register and then faults, and none of the tests has
one. The refresh after a restore is there because the restore can change the segments, not
because a test demands it.

## E038: One translation for an instruction that reads and writes its operand (2026-11-15)

- **Hypothesis**: `add [mem], reg` and its like read the operand through `seg_read` and write
  it back through `seg_write`: the address, the bound, the page test, a TLB lookup and the
  test that the page is in RAM are done twice, once with the read TLB and once with the write
  TLB. A page with a write entry at this privilege level can be read as well, so one lookup in
  the write TLB gives the place in RAM for both, and when it misses the old way still does
  everything. `probe/bench32.asm` has `add [ebx+8], eax` at about 200 host instructions where
  a load is about 130. For the executors of ADD, OR, AND, SUB, XOR with a register or an
  immediate, INC and DEC on a 32-bit memory operand: about 35 host instructions off each, and
  on a boot, where a few percent of instructions are of this kind, about 1% of the host
  instructions and somewhat less of the cycles.
- **What changed since last time**: E024's third candidate, after E037 made the access path
  itself shorter. The gain expected is small; it is taken because it is cheap and because
  the instruction count has been followed by the cycles at about half since E033.
- **Next move for each result**:
  - Instructions and cycles fall → keep
  - Instructions fall by less than 0.5% on the boot → these instructions are rarer than
    thought; keep the change, and stop shaving the access path: what is left of the list is
    REPNE SCASB a page at a time
  - A test fails or the guest instruction count changes → the write TLB was trusted for a
    page it does not cover (the lookup has to be the one `seg_write` makes, privilege level
    included), or a flag is set before a fault can still happen
- **Cut-off**: The same day; deliberately wrong builds (the read TLB used for the lookup; a
  byte of the result not stored) must fail a test.

### Result

2026-11-15. **Kept: about 1% of the boot, instructions and cycles alike.**

| | main | With one translation |
|---|---:|---:|
| Linux boot, host instructions | 188.5 billion | 186.4 billion (1.1% fewer) |
| Linux boot, cycles, three alternating runs | 33.54, 33.42, 33.37 billion | 33.11, 33.15, 33.15 (1.0% fewer) |
| `add [ebx+8], eax` in `probe/bench32.asm`, per iteration with DEC and JNZ | 357.7 instructions, 56.6 cycles | 332.6, 54.1 |
| `inc dword [ebx+8]` | 350.7, 55.0 | 327.6, 52.7 |
| test386 | 18.44 billion instructions, 2.98 billion cycles | 18.36 billion, 2.87 billion |
| bench.bin (real mode) | 96.11 billion, 14.08 billion cycles | 95.68 billion, 14.09 billion |

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 65 of 65;
test386 is byte for byte the reference. The executors for ADD, OR, AND, SUB and XOR with a
register or an immediate, and INC and DEC, on a 32-bit operand: 25 host instructions off each
with a memory operand, not the 35 expected (the compiler had already shared part of the two
accesses).

**Four wrong builds; two were caught by nothing at first.** The top byte of a result not
stored, and DEC done as INC: caught by the trace tests and test386. The read TLB used for the
look-up, and the segment bound not tested: both passed every test. For the first there is now
`s_rmwro`: with paging on and write protection in ring 0, a page that may be read and not
written is read, then ADD, INC and SUB on it must each take a page fault. For the second,
`s_segbound` now tries ADD and INC against the small segment. It still passed the wrong build
the first time: nothing had written to that page, so the write TLB did not hold it and the
wrong path was never taken. It writes inside the segment first now, and the wrong build fails.

## E039: REPNE SCASB a page at a time (2026-11-15)

- **Hypothesis**: After E035 the elements that still go one at a time through `string_op` on a
  boot are SCASB under REPNE, 5.3 million (a `strlen`), and CMPSB under REPE, 0.55 million.
  Each costs the loop's bookkeeping: the count, the registers saved for a fault, the segment
  and the translation. Scanning the bytes of one page with one translation, as REP MOVS copies
  them (E020), and setting the flags once from the last byte compared, leaves a few host
  instructions a byte. `string_op` is about 2% of a profile, part of it the copies; expected
  about 0.5% of the boot's host instructions and cycles. Small, and the last item on the list.
- **What changed since last time**: E035 took the string instructions without REP; this is the
  one repeated form left that the boot uses in numbers.
- **Next move for each result**:
  - It gives its 0.5% → keep; the list from E024 and the profile is then done, and what
    follows is a new survey, not another item
  - It gives nothing measurable → keep it if the instruction count falls at all; same
    conclusion
  - A test fails or the guest instruction count changes → where the scan stops, what ECX and
    EDI are then, or the flags of the last comparison
- **Cut-off**: The same day; a trace test against rustx86 with a match in the first page, in
  the next page, at the last byte allowed and not at all, for REPNE and REPE, and with a
  count of zero; deliberately wrong builds must fail it.

### Result

2026-11-15. **Kept: 0.3% of the boot's host instructions and about 0.4% of its cycles**, a
little under the 0.5% expected. Linux boot, three alternating runs: 33.01, 32.95, 33.10
billion cycles before; 32.87, 32.91, 32.85 after; host instructions 186.4 to 185.8 billion.
The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 66 of 66 with
the new trace test `u_scas`; test386 is byte for byte the reference and unchanged in cost.
CMPSB under REPE was left as it is (a tenth of the elements).

Seven deliberately wrong builds. Five failed `u_scas` at once; one of them (the scan stopping
one byte early) by never finishing, since a scan that makes no progress repeats for ever
inside one instruction, where the step limit cannot reach it. One passed: a scan that does
not stop at the end of a page. With paging off the next page in linear addresses is the next
page in memory and the answer is the same. The test now ends with paging on and the page after
8000h mapped elsewhere, and that build fails.

**Where the list stands.** Everything named in E024's survey and in E032's profile has now
been tried or ruled out: blocks ruled out by measurement (E032), lazy flags not tried and not
indicated (nothing measured since has pointed at the flags), the rest done. The scripted boot
is at 32.9 billion cycles and 185.8 billion host instructions, from 47.7 and 247.3 this
morning: 20 cycles and 113 host instructions for each guest instruction. By the first branch
of the card, what follows is a new survey and not another item.

## E040: A second survey: where the other ten cycles are (2026-11-16)

Like E024, a survey to find the next experiments, not one hypothesis about one change. Nothing
in `src/` changes on this card.

- **Hypothesis**: A NOP in a row costs 10 cycles and the boot averages 20 for each guest
  instruction. The other ten are in one or more of three places, and which one decides what
  to try next: (a) a stretch of the boot that costs far more than the rest for each
  instruction (paging just turned on, user mode, a driver's loop); (b) what happens between
  runs and around them (entering a run, the general path, interrupts, faults, misses of the
  data TLB), which no executor's cost contains; (c) the dispatch jump being mispredicted,
  which E032's profile put at about 12% of samples and nothing since has addressed.
- **What changed since last time**: E024 compared designs and counted what took the general
  path; E032 profiled once, before E033 to E039 moved a fifth of the cost. This one measures
  three things not measured before: cycles for each stretch of the boot (the same boot stopped
  at a series of instruction counts), how long runs are and what ends them, and the profile
  by address again on today's code.
- **Next move for each result**:
  - One stretch costs more than 1.5 times the average for each instruction → profile that
    stretch by itself and find what it does that the others do not
  - Runs are short (under about 20 instructions) and one cause ends most of them → measure
    what one entry into a run costs, and remove that cause
  - Samples on an executor's first instruction are still 10% or more → an experiment on the
    dispatch itself (a second place to jump from, for the pairs that follow each other most)
  - None of the three, and no single site above about 3% that is not the guest's own memory →
    say so plainly: at this design the interpreter is near its floor, and what is left is a
    change of design (generated code), which is the owner's decision and not an item
- **Cut-off**: The same day. Three measurements, each one build at most; if a measurement
  needs more than a counting build and a profile build, it is dropped and named as not done.

### Result

2026-11-16. **The profiler was wrong about stores, the boot is flat, and two things stand
out of it: rotates done a bit at a time, and what a run's end costs.** Nothing in `src/`
changed; `probe/prof.c` is a different sampler now.

**(a) No stretch stands out.** The same boot stopped at a series of instruction counts,
cycles for each guest instruction in each stretch:

| Guest instructions (millions) | 0-100 | -200 | -300 | -400 | -500 | -600 | -800 | -1000 | -1200 | -1400 | -1600 | -1651 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Cycles each | 18.0 | 18.7 | 13.8 | 16.1 | 24.2 | 15.5 | 20.3 | 23.7 | 20.3 | 22.7 | 20.2 | 16.1 |

The average is 19.9 and the worst stretch is 1.2 times that. The decompressor (to about 394
million) runs at 16.6, the kernel at about 21.

**(b) Runs are 32 instructions long, and half of them end at a page of code.** A counting
build: 49.8 million runs for 1,601.6 million instructions. What ends them: the next
instruction is on another page, 26.6 million (53%); an instruction with no executor, 12.9
million (26%); not in the cache, 8.1 million (16%); within 15 bytes of a page's end, 1.9
million; out of time, 0.17 million. Every end is a trip through the general path, 49.7
million of them.

**(c) The sampler of E032 was biased, and what it said about single stores is withdrawn.**
To attribute samples to guest instructions in spite of merged code, a profiling copy noted the
kind of each instruction before running it, and each sample was counted under the kind last
noted. That put MOVSW (the decompressor's copy) at 5.4% of the boot for 0.5% of its
instructions, 231 cycles each, 92% of it on one 16-bit store: E035's reading again, which
E036 had withdrawn as an effect of merged code. It is not merged code, and it is not time
either. Tried and found to change nothing: the destination at the boot's addresses (68 MB)
instead of under 1 MB, 40 MB of memory never written before, match distances and lengths
drawn at random as an LZ stream has them (`movsw` stays at 16 to 17 cycles in all of these),
and, in the boot itself, the store and the load each made a byte at a time. Then the host's
clock read before and after the executor, summed over the boot:

| Executor | Times | Total | Each, clock calls included |
|---|---:|---:|---:|
| MOVSW | 7.7 million | 0.072 s | 9.3 ns |
| PUSH | 22.4 million | 0.169 s | 7.5 ns |
| `mov [mem], r8` | 19.2 million | 0.156 s | 8.1 ns |

MOVSW takes 0.7% of the boot, not 5.4%. The samples were wrong: the timer signal
(ITIMER_PROF every 200 microseconds) delivered 10 to 12 thousand samples in a boot where 52
thousand were due, and put them by preference on stores into guest RAM. Why it prefers them
was not looked into. `probe/prof.c` now takes its samples from a second thread that suspends
the main one and reads its program counter; it gets the 52 to 54 thousand, two runs agree to
a few tenths of a point, and no store into guest RAM is in its first thirty addresses.

| Where | The signal sampler (E036) | The thread sampler (now) |
|---|---:|---:|
| `exec_short` | 80.5% | 85.6% |
| `exec_general` | 10.3% | 6.4% |
| `shift` | 1.8% | 2.8% |
| `run_until` | 1.4% | 1.9% |
| `string_op` | 2.3% | 0.8% |
| stores into guest RAM, all sites | 12 to 15% | under 0.1% |

What this withdraws: E032's "one store in the general path holds 3.6%" and its explanation
(memory the host has not touched); E034's "`string_op` is 12 to 13%, nine points of it on one
byte store", which is why E035 expected 5% and got 1.2%; E035's "180 cycles a copy" and
E036's explanation of it. What stands, because it was measured in cycles and not read from
samples: every kept or rejected result, and E033's two items (the search was 3.5% in samples
and 3.4% in cycles; `shift` is real, and larger than it looked). **A sample count is a
suggestion until a count of cycles agrees with it.**

**Time by kind of instruction**, with the thread sampler (two boots, 109,000 samples; cycles
each are the share of 32.9 billion divided by the kind's count, and include about one cycle
for the note):

| Kind | Share of time | Share of instructions | Cycles each |
|---|---:|---:|---:|
| `mov r, r/m` | 13.1% | 13.4% | 19.6 |
| `mov r/m, r` | 11.6% | 13.9% | 16.7 |
| Jcc on one flag | 9.8% | 11.7% | 16.7 |
| general path before the opcode is known (49.7 million entries) | 5.8% | | 39 an entry |
| shifts and rotates by a constant, the general executor | 3.9% | 1.8% | 43.7 |
| CMP `r/m, r` | 3.5% | 4.0% | 17.8 |
| ADD `r/m, r` | 3.4% | 4.2% | 15.9 |
| MOVZX from 8 bits | 3.1% | 4.0% | 15.7 |
| LEA | 2.9% | 3.4% | 17.0 |
| every other kind | under 2.8% each | | 13 to 29 |

All executors together are 87.9% and the general path 11.6%, half of which is its entry. The
table is flat: a kind's share of the time is its share of the instructions, within a factor
of 1.5, with one exception. **The exception is kind 8**, the executor that E022 left for what
its one-step shifts do not cover: after E022 that is the rotates. `shift()` rotates one bit
for each pass of a loop, with a `match` in the pass, so a `rol eax, 13` is thirteen passes;
29.5 million of them in a boot (the kernel's hashes) at 44 cycles where a shift takes 14, and
`shift` itself is 2.8% of the samples.

**The dispatch**: 1.8% of samples are on the first instruction after the dispatch jump, and
12.9% after any unconditional jump, most of the rest being the loop's own tail where every
executor rejoins. E033 called 12% "the dispatch's mispredictions"; with the instrument fixed
it is under 2%, and no experiment on the dispatch is indicated.

By the card: (a) no; (c) no; (b) partly. So, in order of what the numbers promise:

1. **Rotates in one step** (next card). 29.5 million at about 27 cycles too many: about 2.4%
   of the boot, plus what `shift` costs the general path.
2. **A run's end.** 49.7 million ends at 39 cycles of entry each, 5.8% of the boot, before the
   instruction itself. More than half are a page change. E024 tried going on into the next
   page inside the run and saw more host instructions and no fewer cycles, on a loop that has
   since been rebuilt (E026 to E030) and with a spread of 2 to 3% between runs; it is worth
   one more measurement with today's loop and alternating runs, and if it fails again the
   entry itself is the thing to shorten.
3. **The floor.** `mov` at 17 to 20 cycles and a NOP in a row at 10 says the executors'
   own work is about half of each instruction and the loop the other half. Nothing in this
   survey points at a way under that short of generated code.

## E041: Rotates in one step (2026-11-16)

- **Hypothesis**: E040's table by kind has one kind out of line: the executor for shifts and
  rotates by a constant that the one-step shifts of E022 do not cover, 43.7 cycles each where
  its neighbours take 14 to 20. After E022 those are the rotates, 29.5 million in a boot.
  `shift()` does a rotate one bit for each pass of a loop with a `match` in it. ROL and ROR in
  one step (two shifts and an OR, CF from the result's lowest or highest bit, OF by the
  formula the loop's end already uses) should bring the kind to about 17 cycles: 29.5 million
  times 27 cycles is 0.8 billion, **about 2.4% of the boot**, and `shift` should fall from
  2.8% of the samples to well under 1%. RCL and RCR keep the loop: a rotate through CF is 33
  bits wide, and nothing counted says the boot uses them.
- **What changed since last time**: E033 took the shifts by CL out of `shift()` and got 0.9%
  where the biased sampler said 3%. This is chosen from a table of time by kind made with a
  sampler that agrees with a clock (E040), and it is the rotates, which E033 left alone.
- **Next move for each result**:
  - About 2% or more → keep; the table is a good guide, and the next card is a run's end
  - Under 1% → the kind's 44 cycles were not the loop (the call, or the memory forms); time
    the executor with a clock as E040 did before anything else
  - A test fails or the guest instruction count changes → CF or OF of a rotate, most likely
    for a count that is a multiple of the width (8-bit and 16-bit rotates by 8, 16 or 24)
- **Cut-off**: The same day; `tools/difftest.sh` 66 of 66, test386 (which has the flags of
  rotates from real hardware), the boot's count, and deliberately wrong builds that the tests
  must fail.

### Result

2026-11-16. **Kept: about 2% of the boot's cycles and 1.6% of its host instructions; the
first branch.** ROL and ROR are one step in `shift()` for every width, so the general path and
the executor for a count in CL have it too. RCL and RCR keep the loop.

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| main | 185.8 to 186.0 billion | twelve runs, 32.91 to 34.60 billion |
| with rotates in one step | 182.9 billion | twelve runs, 32.81 to 33.55 billion |

The machine was busier than yesterday and main's runs spread by 5%, so the pairs decide:
twelve pairs run back to back, eight with main first and four with it second. The new build
is the faster in eleven. The differences average 2.5% with main first and 1.7% with it
second; **about 2%**, where the card said 2.4%. `shift` fell from 2.8% of the samples to 0.8%
as predicted. test386 is unchanged in cost (18.37 billion instructions, 2.88 billion cycles
both ways); it has few rotates.

The boot still takes 1,651,240,001 guest instructions; `tools/difftest.sh` is at 66 of 66;
test386 is byte for byte the reference. Six deliberately wrong builds all fail: CF taken from
the wrong end for ROL and for ROR, ROR turning left, the count not reduced by the width, CF
left alone when the count is a multiple of the width, and ROL by one bit too few. `t_shift`
fails all six; test386 fails five (not the unreduced count).

The table by kind was a good guide to the size: 2.4% predicted from it, about 2% measured.
That is the first prediction from a profile in this ledger to come out near its figure
since E033's search, and the first from samples by kind. The next card is a run's end.

## E042: A run that goes on into a page the TLB already knows (2026-11-16)

- **Hypothesis**: 26.6 million runs in a boot end because the next instruction is on another
  page of code (E040, 53% of all ends). Each such end leaves `exec_short`, copies the whole CPU
  into `saved`, enters the general path (39 cycles before the opcode is known), runs the one
  instruction there by its executor (E034), returns through `step` and the run loop, and
  enters `exec_short` again. All the general path does for it is translate the new page. If
  the run looks the page up in the read TLB itself and, on a hit, sets `code_page` and
  `code_phys` and starts over on the new page, the trip is not made. A miss, or anything else
  unusual, ends the run as before, so every page fault is still raised by the general path at
  the moment it is raised today. Expected: 26.6 million times about 39 cycles is 1.0 billion,
  **about 3% of the boot's cycles**, if nearly all of those pages are in the TLB.
- **What changed since last time**: E024 translated the new page inside the run and saw 2.6%
  more host instructions and cycles within a spread of 2 to 3%; why was not found. Three
  things differ. The loop is not the one of E024 (E026 to E030 rebuilt it, and E034 changed
  what a page change costs). The inner loop is left exactly as it is: its page, its place in
  RAM and its bound stay constants, and a change of page leaves it and enters it again from an
  outer loop that works them out anew, instead of making them variables that the loop carries.
  And the judgment is by pairs run back to back (E041), which see 1%.
- **Next move for each result**:
  - 2% or more → keep; the next card is the other large end, an instruction with no executor
    (12.9 million), by its opcodes
  - Under 1%, or more host instructions again → count how many page changes the TLB probe
    lets through and what the inner loop compiled to; if the count is high and the loop the
    same, a run's end does not cost what E040's table says, and the entry is timed with a
    clock before anything else is tried on it
  - A test fails or the guest instruction count changes → the run went on where the general
    path would have faulted or taken an interrupt: the probe, or the bound on the new page
- **Cut-off**: The same day; `tools/difftest.sh` 66 of 66, test386, the boot's count, twelve
  pairs, and deliberately wrong builds that the tests must fail.

### Result

2026-11-16. **Kept: about 2.5% of the boot's cycles and 1.1% of its host instructions, where
the card said 3%; the first branch.** `exec_short` has an outer loop, one pass for each page of
code. The inner loop is the one it was. When the next instruction is on another page it looks
in the read TLB, for the current privilege level; on a hit it makes that the page of code,
exactly as the general path would, and the outer loop works out the page's constants again. On
a miss the run ends as before and the general path translates, so a page fault is raised where
it always was.

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| main | 183.06 to 183.14 billion | twenty runs, 31.64 to 33.40 billion |
| with runs that go on | 181.06 to 181.07 billion | twenty runs, 30.84 to 32.85 billion |

Twenty pairs run back to back. The first twelve were on a busy machine (a load of 6) and
spread from 1.5% slower to 5.4% faster: 3.2% on average with main first (eight pairs), 0.5%
with it second (four). The last eight, on a quieter machine and with the order strictly
alternating, gave 2.0, 2.3, 2.5 and 3.4% with main second and 2.5, 2.7, 3.0 and 6.3% with it
first. The new build is the faster in eighteen of the twenty. **About 2.5%**; the build run
second has an advantage of about a point, as in E041, which is why the order alternates.

Unlike E024's attempt, host instructions fell, by 2.0 billion. How many of the 26.6 million
page changes the probe lets through was not counted; at the 39 cycles of E040's table the
cycles saved are about 21 million of them. test386 takes 1.3% more host instructions (18.60
billion against 18.36) for the same cycles (2.87 billion both ways); why more was not looked
into.

The boot still takes 1,651,240,001 guest instructions; test386 is byte for byte the
reference; `tools/difftest.sh` is at 68 of 68, with one new test.

**The tests did not cover this, and now they do.** Of the deliberately wrong builds, "the TLB's
tag not compared" passed every test and failed only the boot (a triple fault), and "the
supervisor's TLB entry taken in user mode" passed everything, the boot included: Linux never
jumps from ring 3 into a supervisor's page that ring 0 has just read. `tests/asm/s_runpage.asm`
is a self-check for both: two functions on pages that share a TLB slot, called in turn, and a
supervisor's page that ring 0 runs first and ring 3 then calls six times, each call a page
fault. With it, three wrong builds fail (those two, and "the new page's place in RAM not
taken", which test386 also fails). A fourth, "one page too far", fails nothing and is not
wrong: it never finds a page to go on to, and is main at more cost. Writing the test found
nothing in g86m and two things in the test: 140000h is 40000h while address line 20 is off,
and DS is emptied on the way to ring 3 and has to be loaded again before real mode.

The next card is the other large end of a run: an instruction with no executor, 12.9 million
ends, by opcode.

## E043: A third survey: what interpreters other than the first three do (2026-11-16)

A survey at the owner's suggestion, like E024, to find the next experiments. Nothing in `src/`
changes on this card, and nothing in the sources read is measured here.

- **Hypothesis**: E024 read rustx86, v86 and VirtualBox's IEM, two of which lean on a JIT.
  E040 then found the boot flat: every kind of instruction costs 16 to 20 cycles where a NOP
  costs 10, and no single site stands out. Emulators that are interpreters and nothing else
  have had to get under that by design, not by removing a hot spot, and some of what they do
  is not in E024's table. The candidates sought are those that take work off every
  instruction or every memory access: how a memory operand is found and checked (the TLB
  entry and what one comparison of it covers), how code that is written to is noticed (g86m
  compares eight bytes for every instruction it runs), what an executor is specialised on,
  and the flags.
- **What changed since last time**: Different sources: Bochs (an interpreter only, tuned for
  twenty years, with papers on why), QEMU's software TLB, the interpreters of 86Box and
  DOSBox, and the small ones (Halfix, tiny386, blink). And a different question: E024 asked
  what the others have that g86m lacks; since E026 to E032 the ledger knows which work an
  instruction waits for (E032: blocks are off the list, the load on the chain is 2 cycles of
  10), so each candidate is judged by whether it shortens that or only lowers a count.
- **Next move for each result**:
  - A technique removes work from every memory access or every instruction, and g86m's own
    code shows the work is there → a card for it, with the cost counted on g86m first (host
    instructions on the path, and a build made only to be timed, as E032 did for the load)
  - A technique is what the ledger already tried or measured as not paying (blocks, fusing a
    compare with its jump, a larger cache) → listed as such with the entry that says so, no card
  - Nothing of the first kind → say so; with E040's third item that makes two surveys that
    end at "generated code or nothing", and the decision is the owner's
- **Cut-off**: The same day. Two research passes over the sources; each claim carries a file
  or function name or is marked as not verified.

### Result

2026-11-16. **Four candidates, two of them with a size measured on g86m; three things the
others do that g86m's own numbers say would not pay.** Nothing in `src/` changed. Read, with
file and function names for each claim, by two research passes: Bochs (`bochs/cpu`: `cpu.cc`,
`icache.h`, `tlb.h`, `access2.cc`, `stack.cc`, `lazy_flags.h`, `faststring.cc`, its `CHANGES`,
and the slides of Mihocka and Shwartsman's 2008 paper); QEMU's software TLB
(`accel/tcg/cputlb.c`, `include/exec/tlb-common.h`, `tcg/aarch64/tcg-target.c.inc`) and lazy
flags; 86Box (`src/mem/mem.c`, `386_common.h`, `x86_flags.h`); DOSBox-X (`paging.h`,
`flags.cpp`); Halfix (`mmu.c`, `access.c`, `smc.c`, `eflags.c`); tiny386 (`i386.c`). Not read:
PCem, the text of the 2008 paper, Bochs's `fetchdecode32.cc`; blink from its README only. None
of their published figures was checked, and none is for one technique alone except Bochs's
"10% for chaining, 5 to 10% more for linking traces".

**What they have in common that g86m does not.**

| | g86m | Bochs | QEMU | Halfix, 86Box |
|---|---|---|---|---|
| Is the cached instruction still what is in memory? | compare its first eight bytes, every time it runs | a stamp for each physical page, tested by every write (`bxPageWriteStampTable`, `decWriteStamp`) | a page with code has no plain write entry in the TLB (`TLB_NOTDIRTY`, `notdirty_write`) | the same as QEMU (`cpu_smc_page_has_code`; `page_lookup`) |
| The cache's key | the linear address | the physical address | the physical address | the physical address |
| One comparison of a TLB entry covers | the page | the page, and that the access does not cross it (the index and tag are taken from the last byte), and that it is RAM | the same, and alignment; the entry holds host address minus guest address | no tag at all: a table with an entry for every page, a byte of permissions for the four modes |
| Size of the data TLB | 256 for each of read, write, supervisor, user | 2,048, one table, permission bits tested after | 256 and up, resized at a flush by how full it was, and 8 victims | 8,192 live entries of a million |
| The stack | as any memory | a window: one add and one comparison for a push or pop (`espPageBias`, `espPageWindowSize`, `espHostPtr`) | as any memory | as any memory |
| A register form and a memory form of one instruction | one executor that tests which | two handlers | (generated code) | - |
| Flags | at once | lazy, two words, no record of the operation | lazy, with the operation | lazy |

**Measured on g86m, for the first row.** A build made only to be timed, with the comparison
of the eight bytes taken out of `exec_short` and nothing put in its place. It goes wrong
before 480 million instructions, as it must; up to 390 million (the decompressor) it ends in
the same state as main:

| First 390 million instructions | Host instructions | Cycles, two alternating runs |
|---|---:|---:|
| main | 40.63, 40.68 billion | 6.53, 6.61 billion |
| without the comparison | 36.73, 36.72 billion | 6.26, 6.21 billion |

9.7% of the host instructions and **about 5% of the cycles**: that is the most the first row
can give. What it would cost is what a write to a page with code costs, times how many there
are. Counted over a boot, with a mark for every physical page an instruction was ever decoded
from (1,483 pages by the prompt), never taken off: 194.8 million writes by the short path, of
which **8,406** to a marked page (141 pages); 615,701 pages written by the bulk string
routine, 11,908 of them marked; 692,024 writes by the general path, 261 to a marked page.
About twenty thousand in all. The others' way costs g86m next to nothing on the write side.

**Counted on the way: the TLB is refilled far more often than it need be.** 4.26 million page
walks in a boot (3.68 million for a read, 0.58 million for a write), and 90,277 flushes of
the whole TLB behind them: 70,855 are INVLPG, which g86m answers by flushing everything
(70,029 of them in the first 480 million instructions, while the kernel builds its page
tables: 1.32 million walks, 19 for each flush), and 19,416 are writes of CR3 (after that:
2.94 million walks, about 145 for each flush). g86m's i686 does not offer global pages in
CPUID, so a change of address space throws the kernel's own pages out every time. What a
walk costs was not measured.

**Candidates, in the order the numbers suggest.**

1. **Notice a write to code at the write, not at every instruction.** Key the decode cache by
   physical address (a run already has it: the place in RAM it reads the bytes from), mark
   each physical page that has entries, keep marked pages out of the write TLB, and on the
   slow path that such a write then takes, empty the slots for the fifteen addresses before
   it and those it covers. Upper bound 5% of the cycles; the write side is twenty thousand
   slow writes a boot. What has to be right: every way into RAM that is not `seg_write` (the
   bulk string routine, the one-translation path of E038, the BIOS's disk reads), and a page
   that held code once and is data now. The largest candidate since E029.
2. **INVLPG for one page, then global pages.** The first is a few lines and gives what a walk
   costs (host instructions and cycles for each walk it saves, of at most 1.3 million); that
   figure times 2.9 million says whether global pages (CPUID, CR4, a bit for each entry) are
   worth their card.
3. **Two executors for `mov`, one for a register and one for memory.** `mov r, r/m` and
   `mov r/m, r` are 27% of all instructions (E040), at 19.6 and 16.7 cycles, and each tests
   twice at run time which form it is; the host predicts that test by the executor, not by
   the guest instruction, so alternating forms are the bad case. Bochs gives "reducing
   misprediction" as the reason for its two handlers. Size unknown; the change is in
   `classify` and two arms of `run_short`.
4. **The memory operand itself**: one comparison for page, crossing and RAM, with the tag
   taken from the access's last byte (Bochs, QEMU), and a window for the stack (Bochs). By
   E037 (3.6% of the instructions gave 1.8% of the cycles) each is about a point; a build
   made only to be timed first.

**Not candidates, and why.**

- **Lazy flags** (all of them have it, in three different forms). E040's table has ADD at
  15.9 cycles and `mov r/m, r` at 16.7: computing the flags at once costs nothing that the
  next instruction waits for. E024's fifth item said the same in advance.
- **Linking traces, a successor remembered in the branch** (Bochs). E032: no arrangement of
  entries can win more than 2 cycles of 10, and a run already goes from instruction to
  instruction without leaving its function.
- **A table with an entry for every page, a victim TLB, resizing** (Halfix, 86Box, DOSBox;
  QEMU). They cure misses where two pages want one slot. g86m's walks follow flushes, 19 and
  145 at a time; whether any are left over for conflicts is a question for after the second
  candidate.

By the card: the first branch, for candidates 1 and 2. The next card is the first.

## E044: A write to code is noticed at the write, not at every instruction (2026-11-16)

- **Hypothesis**: Every instruction of a run loads eight bytes of guest memory and compares
  them, under a mask, with the bytes its entry was decoded from. Taken out and replaced by
  nothing, that is 9.7% of the host instructions and about 5% of the cycles on the first 390
  million instructions of the boot (E043). Bochs, QEMU, Halfix and 86Box do without it by
  noticing the write instead, and on g86m the writes that would have to be noticed are about
  twenty thousand in a boot of 195 million (E043). So, for 32-bit code:
  - an entry is found by the instruction's **physical** address and is good for as long as it
    is there: the same bytes at another linear address, or other bytes at the same one, are
    then no question at all. A run carries the physical address of the next instruction and
    the page's difference to linear addresses, so the load from one instruction to the next
    is the same one load (E028);
  - a physical page with entries is **marked**, and a marked page gets no entry in the write
    TLB, so the short paths for a write never see it and cost what they cost now;
  - every other store into RAM (`set_mem8/16/32`, the bulk string routine) looks at the mark,
    and for a marked page empties the entries that begin in the fifteen bytes before the
    write or inside it. After sixteen such writes the page is taken to be data now: all its
    entries go, and the mark with them.

  16-bit code keeps the comparison: it runs on the general path only, and there code and
  data share pages as a rule. Expected: **3 to 4% of the boot's cycles** and about 8% of its
  host instructions.
- **What changed since last time**: E030 made the comparison cheaper (8% of the instructions,
  1% of the cycles); this removes it, together with the load of the code bytes that feeds it,
  and E043 measured what that is worth before anything was built. Nothing in the ledger has
  changed how an entry is known to be valid since E016.
- **Next move for each result**:
  - 2.5% or more of the boot's cycles → keep; the next card is INVLPG for one page
  - 1 to 2.5% → keep, and say that the bound of the decompressor does not carry to the
    kernel; count slow writes and emptied entries on the boot before the next card
  - Under 1% → not kept: the loop waits on something the comparison was hiding behind
  - test386 or bench.bin slower by 2% or more → pages that hold code and data together;
    count their slow writes, and try a mark for a part of a page (Bochs: 128 bytes)
  - A test fails or the guest instruction count changes → a way into RAM that does not look
    at the mark, or an address carried in a run that is linear where it should be physical
- **Cut-off**: The same day; `tools/difftest.sh`, test386, the boot's count, bench.bin, a
  self-check for each way of writing to code and for one page at two addresses, deliberately
  wrong builds, twelve pairs.

### Result

2026-11-16. **Kept: about 3.5% of the boot's cycles and 8.5% of its host instructions, as the
card said; the first branch. And the fourth: the 16-bit benchmark is 3.8% slower, for a
reason that is not the card's.** A run no longer loads the bytes of the instruction it is
about to execute.

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| main | 181.04 to 181.05 billion | twelve runs, 30.96 to 32.42 billion |
| with the write noticed | 165.65 billion | twelve runs, 29.87 to 30.62 billion |

Twelve pairs run back to back, the order alternating: the new build is the faster in all
twelve, by 3.1 to 4.8% in ten of them (6.2 and 7.2% in the two where main's run was
disturbed); the median is 3.6%. Three earlier rounds on a quiet machine gave 30.88 to 30.95
billion against 29.78 to 29.93. test386 takes 3.2% fewer host instructions (18.03 billion
against 18.62) and about 1% fewer cycles (2.88 billion against 2.90 to 2.93).

What was built is the card's design with one difference: the physical address finds an entry
for 16-bit code as well (and there its bytes are still compared), because one kind of key for
both cost the 16-bit path least; see below. `exec_short` reckons in physical addresses inside
a page and hands the executors the code segment's base less the page's distance from linear
to physical, so what the guest sees (a return address, the instruction pointer of a fault) is
linear as before. A page of RAM is marked when an entry of 32-bit code is made in it;
`tlb_fill_write` makes no entry for a marked page; `set_mem8/16/32` and the bulk string
routine look at the mark and call `code_written`, which empties the entries that begin in the
fifteen bytes before the store or inside it, and after sixteen stores empties the page's
entries and takes the mark away.

The boot still takes 1,651,240,001 guest instructions; test386 is byte for byte the
reference; `tools/difftest.sh` is at 72 of 72 with two new tests.

**Tests.** `s_codewrite` changes a function's second byte in six ways (a plain 32-bit store,
a read-modify-write, a byte store, a bulk string store, a store that begins in the page
before, a store after the page has lost its mark and got it again) and calls the function
after each. `s_codemap` runs one physical page at two linear addresses, where the code
returns its own address, and two physical pages in turn at one linear address. Eleven
deliberately wrong builds all fail: a 32-bit store or a byte store that does not look at the
mark, a marked page given a write TLB entry, marking that leaves the write TLB alone, the
bulk store not looking, only entries that begin at the store emptied, only the first byte's
page looked at, a page that loses its mark and keeps its entries, and three that confuse
linear with physical. The first version of `s_codewrite` let two of them pass, and not for
want of a case: it compared two counters at the end, and a wrong step moved a count from one
to the other where a later wrong step moved it back. The counters now go into a sum that
depends on the order after every step. **A self-check that adds up should add up in a way
that two errors cannot cancel.**

Not covered: a 16-bit store (`set_mem16`) into code has no wrong build of its own. And the
BIOS's stores into the screen and its data area (`bios.goose`) go straight to RAM without a
look at the mark; no 32-bit code is there.

**The 16-bit benchmark.** bench.bin, 369,095,178 instructions of real-mode code:

| | Host instructions | Cycles |
|---|---:|---:|
| main | 95.64 billion | 14.03 to 14.05 billion |
| with the write noticed | 98.72 billion (3.2% more) | 14.57 to 14.59 billion (3.8% more) |

By the card that is the fourth branch, but its guess (pages with code and data together) is
not the reason: no page of the benchmark is ever marked, only 32-bit code marks a page, and
the cache is hit 369,095,153 times and missed 25 in both builds. The 8.4 host instructions
more for each guest instruction are the compiler's code for `exec_general`, 139 KB of it,
after a change of a few lines at its head. Taking the stores' look at the mark out again
changes nothing, nor does the TLB's; the lookup in `exec_general` alone, put into main,
brings all of it. The ways of writing those lines that were tried, by the benchmark:

| How the general path's lookup is written | Host instructions | Cycles |
|---|---:|---:|
| main: slot and tag from the linear address | 95.64 billion | 14.0 billion |
| the key chosen by the code's size (first version) | 99.09 | 14.8 |
| the same, with the slot in a variable set twice | 102.04 | 15.0 |
| the physical address for both sizes (kept) | 98.72 | 14.6 |
| a block for each size, the 16-bit one as in main | 96.92 | 17.9 |
| the same, the 16-bit block first | 96.22 | 17.6 |
| three small changes to that | 96.11 to 96.85 | 17.4 to 18.0 |

**The benchmark has two states, and which one a build is in is not in the source.** The
variants with the fewest instructions are a quarter slower. A profile by address of one of
them has 16.7% of all samples on one instruction, the load of `dc_cur` at the head of the
ModRM decoder, which comes a few instructions after it is stored; a profile of main has the
same instructions there with 0.7%. It is not the stack's position (padding the environment
by 8 to 1,024 bytes moves neither build), not the load's width (a 32-bit `dc_cur` is as
slow), and the variable is at the same address in every build. E021 met the same step (14.2
against 17.2 billion) and put it down to a global's alignment; whatever it is, it is older
than this card. So bench.bin's cycles say which state a build is in, and its host
instruction count says what a change costs; the two must be read apart. Kept is the best
variant that is in the fast state. That the 16-bit path is now 3 to 4% slower is the price
of this card as it stands.

By the card: the first branch for the boot, so the next card is INVLPG for one page. Left
open, in this order: the 16-bit general path (why eight more instructions, and what the load
of `dc_cur` waits for; taking `dc_cur` out of memory between the lookup and the decoder
would answer both); how often a page loses its mark on a boot, which was not counted, and
whether sixteen is the right number.

## E045: INVLPG forgets one page (2026-11-16)

- **Hypothesis**: g86m answers INVLPG by emptying the whole TLB. A boot has 70,855 of them
  (E043), 70,029 in the first 480 million instructions while the kernel builds its page
  tables, and 1.32 million page walks follow in that stretch, 19 for each. Forgetting only
  the page named (its slot in the read and the write TLB for both privilege levels, and the
  three one-entry caches if they hold it) leaves the rest of the TLB in place and should take
  most of those 1.32 million walks away. What a walk costs is not known, which is half the
  reason for this card: at 100 to 300 host instructions each the saving is 0.1 to 0.25% of
  the boot's host instructions, **well under 1% of its cycles**, and visible as cycles only
  on the first 480 million instructions (1 to 2% there).
- **What changed since last time**: Nothing in the ledger has touched how the TLB is emptied.
  The count of flushes by cause is E043's.
- **Next move for each result**:
  - Walks fall by a million or so and the stretch's instructions and cycles with them → keep.
    The saving divided by the walks saved is a walk's cost; times the 2.9 million walks that
    follow a write of CR3, if that is 1% of the boot's cycles or more (a walk at about 100
    cycles) → a card for global pages (CPUID, CR4.PGE, a bit for each TLB entry); if less,
    global pages are off the list and the next card is the two executors for `mov`
  - Walks do not fall → the walks after an INVLPG are of the page itself or of pages not seen
    before; count walks by whether the page was in the TLB at the last flush
  - A test fails or the guest instruction count changes → something relied on the whole TLB
    going: a translation kept somewhere this does not look (a run's page of code, the
    one-entry caches)
- **Cut-off**: The same day; `tools/difftest.sh`, test386, the boot's count, a self-check
  with a wrong build for each thing that must be forgotten.

### Result

2026-11-16. **Kept: a million page walks fewer, 0.5% of the host instructions of the first
480 million guest instructions and 0.15% of the boot's; in cycles too small to see, as the
card said. A walk costs about 230 host instructions, and global pages are off the list.**
`forget_page` in `state.goose`; `flush_tlb` is now for CR0 and CR3 only.

| | Page walks | Whole flushes | Host instructions | Cycles |
|---|---:|---:|---:|---:|
| First 480 million, main | 1,324,343 | 70,044 | 46.99 to 47.00 billion | three runs, 7.94 to 7.95 billion |
| First 480 million, one page | 314,196 | 15 | 46.76 to 46.77 billion | three runs, 7.91 to 7.94 billion |
| Boot to the prompt, main | 4,261,127 | 90,277 | 165.69 to 165.71 billion | |
| Boot to the prompt, one page | 3,195,380 | 19,422 | 165.39 to 165.50 billion | |

The walks that went are 1.01 million in the stretch and 1.07 million in the boot; the
stretch lost 0.234 billion host instructions, **232 for each walk saved**, the flushes
themselves included (seventy thousand times 1,024 tags). The cycles moved by 0.2%, inside
the spread of three runs. At the boot's 5.5 host instructions a cycle a walk is about 40
cycles.

**Global pages are not worth their card.** After the first 480 million instructions 2.88
million walks are left, about 148 behind each of 19,407 writes of CR3. If global pages took
every one of them away, that is 0.67 billion host instructions and about 0.12 billion
cycles: 0.4% of the boot, under the 1% the card asked for, for a bit in every TLB entry, a
new control register bit and a feature the kernel then relies on. Off the list, with the
figure; so are a larger TLB and a table for every page (E043), which could only save walks
that are not there.

The boot still takes 1,651,240,001 guest instructions; test386 is byte for byte the
reference; `tools/difftest.sh` is at 76 of 76 with two new tests. `s_invlpg` changes a page
table entry, names the page and uses it again, for a read, a write, code called from
elsewhere, and code that names its own page and goes on; `s_invlpgu` does it for a page that
ring 3 reads and writes. Eight deliberately wrong builds all fail: each of the four TLB
entries left in place, each of the three one-entry caches left in place, and the slot of the
wrong page. Two of them passed the first version of the test for the same reason: the thing
to be forgotten was not there when INVLPG came (the stack's first read had become the last
page read; the test's own INVLPG had already taken the page of code out of the TLB). **A
test that something is forgotten has to make sure first that it is remembered.**

By the card: the first branch, and its second half says global pages are off. The next card
is the two executors for `mov`.

## E046: A `mov` between registers has its own executor (2026-11-16)

- **Hypothesis**: `mov r, r/m` and `mov r/m, r` are 27% of a boot's instructions (E040), at
  19.6 and 16.7 cycles. Each executor serves both forms of its operand and asks twice which
  it has (`short_ea`, then `short_read` or `short_write`: is `mm` a register?). The host
  predicts that test by where it is in `run_short`, not by the guest instruction, so it is
  right only as often as one `mov` has the form of the one before; Bochs has a handler for
  each form and gives misprediction as the reason (E043). With an executor for the register
  form (one for each opcode, a load and a store of `cpu.regs`), and the old two left for
  memory with the tests gone, a `mov` loses two tests and about four host instructions:
  about 1% of the boot's host instructions, and **0.5 to 1.5% of its cycles** if the tests
  were mispredicted often; next to nothing if they were not.
- **What changed since last time**: E022 gave the arithmetic executors their operation and
  E033 the shifts theirs; no executor has been split by the form of its operand. E040's
  dispatch figure (under 2% of samples on the first instruction after the dispatch jump) is
  about the jump into an executor, not about tests inside one.
- **Next move for each result**:
  - Cycles fall by 0.5% or more over pairs → keep, and the same split for the arithmetic
    executors with a register or memory operand (CMP, ADD, TEST: 12% of instructions)
  - Instructions fall and cycles do not → the tests were predicted; taken out again, and no
    split of the others. The next card is then the memory operand itself (E043's fourth)
  - A test fails or the guest instruction count changes → the two registers of a `mov`
    taken the wrong way round for one of the opcodes
- **Cut-off**: The same day; `tools/difftest.sh`, test386, the boot's count, wrong builds,
  twelve pairs.

### Result

2026-11-16. **Kept: about 2% of the boot's cycles for 0.85% of its host instructions; more
than the card said, and the first branch.** Kinds 38 and 39 are `mov` between registers by
opcode 8B and by 89; kinds 1 and 2 are for memory only and ask nothing.

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| main (with E045) | 165.41 to 165.62 billion | twelve runs, 29.83 to 30.43 billion |
| with the register form apart | 164.02 to 164.11 billion | twelve runs, 29.29 to 29.84 billion |

Twelve pairs run back to back, the order alternating: the new build is the faster in all
twelve, by 0.65 to 3.1%, 1.9% on average. The cycles fell by more than twice what the
instructions did, which is what a test that was mispredicted looks like; the card's upper
figure was 1.5%. test386 (18.02 to 18.06 billion host instructions, 2.86 to 2.90 billion
cycles) and bench.bin (98.71 to 98.73 billion, 14.53 to 14.66 billion) are as they were.

The boot still takes 1,651,240,001 guest instructions; test386 is byte for byte the
reference; `tools/difftest.sh` is at 78 of 78 with one new test. Four deliberately wrong
builds all fail: each register form the wrong way round, 8B from memory taken for registers,
89 between registers taken for memory. The first of them passed every test there was: an
assembler writes a move between registers with opcode 89, so 8B with a register operand was
in no test, and a compiler seldom writes it either. `s_movrr` has both, as bytes.

One slip on the way: the first build of this did not compile (kinds 38 and 39 were in the
arm for kinds that do nothing), the command's output was cut to its last lines, and three
pairs were timed against the old binary under the new name before the equal instruction
counts gave it away. **A build whose output is not read in full is not known to have
happened.**

By the card: the next is the same split for the arithmetic executors that take a register or
memory (CMP, ADD, TEST and the rest of that grid).

## E047: A register form apart for the executors whose operand is of both forms (2026-11-16)

- **Hypothesis**: E046's card said "the arithmetic executors next". Counted first, by kind
  and by form of the operand over a boot, and the count changes which ones. `mov r, r/m` was
  from memory every time (13.5% of instructions, no register form among them): its test was
  always predicted, and what E046 won came from `mov r/m, r` alone, 7.3% to memory and 6.7%
  between registers. That is 0.57 billion cycles for 110 million instructions of the form in
  the minority, **about 5 cycles for each**. ADD, XOR, AND, SUB and the immediates are
  register forms almost every time (ADD 4.15% against 0.08%) and so predicted. The executors
  that are of both forms are six:

  | Kind | To or from memory | Between registers |
  |---|---:|---:|
  | CMP `r/m, r` | 1.84% | 2.13% |
  | MOVZX from 8 bits | 3.00% | 0.97% |
  | MOVZX from 16 bits | 0.53% | 1.02% |
  | CMP `r/m, imm` | 0.25% | 1.24% |
  | TEST `r/m8, imm8` | 0.51% | 0.51% |
  | `mov r/m8, r8` | 1.01% | 0.15% |

  The minority forms together are 4.25% of all instructions, 70 million. A kind for the
  register form of each, and the old kinds left for memory without the tests: at E046's 5
  cycles each, 0.35 billion, **about 1.2% of the boot's cycles**, for about 0.4% of its
  host instructions.
- **What changed since last time**: E046 split by guess (the two most frequent kinds) and
  half of the guess was idle. This splits by a count of which kinds are of both forms, and
  predicts from E046's own figure.
- **Next move for each result**:
  - 0.8% or more → keep; "cycles for each instruction of the minority form" is then a figure
    to predict with, and the next card looks for other tests inside an executor that go
    both ways (the 8-bit register's high or low half, a conditional jump's kind)
  - Under 0.5% → not kept; E046's gain was something else about `mov r/m, r` (the store),
    and the figure is withdrawn
  - A test fails or the guest instruction count changes → a register form with its two
    registers the wrong way round, or flags of a CMP or TEST from the wrong operand
- **Cut-off**: The same day; `tools/difftest.sh`, test386, the boot's count, wrong builds,
  twelve pairs. The build's whole output is read.

### Result

2026-11-16. **Not kept: the host instructions fell by 0.36% as the card said, and the cycles
did not move. The figure the card predicted with is withdrawn, and so is E046's
explanation of itself; E046's gain stands.** The six kinds are out again; `src/` is as it
was after E046.

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| main (E046) | 164.07 to 164.16 billion | twelve runs, 29.29 to 29.73 billion |
| with the six register forms | 163.47 to 163.58 billion | twelve runs, 29.25 to 30.21 billion |

Twelve pairs, the order alternating: the differences run from 1.8% slower to 1.1% faster,
seven of twelve faster, 0.04% slower on average. By the card's second branch: under 0.5%,
not kept, and "5 cycles for each instruction of the minority form" predicts nothing.

**Which half of E046 its gain came from: neither.** Two builds, each with one half of E046
undone, six rounds of four builds in turn (medians, billions of cycles):

| | Cycles | Against E046 |
|---|---:|---:|
| E046 | 29.36 | |
| `mov r, r/m` with its two tests back (it is from memory every time) | 29.46 | 0.3% more |
| `mov r/m, r` one executor for both forms again | 29.48 | 0.4% more |
| both undone (E045) | 29.85 | 1.7% more |

Each half alone keeps three quarters of the gain, so the gain is not the sum of two
effects, and it is not "a test that was mispredicted", which only the second half could
be. What the two halves have in common is that `run_short` no longer has `short_read` and
`short_write` in its two most frequent arms; the gain is the compiler's code for the loop
as a whole, and this card's count by form does not say where it would come again.

**Is E046's gain where the code landed? No.** The question had to be asked after E044 (a
benchmark with two states) and after the table above. The same source built with a few
lines that never run added to `main`, which is ahead of the run loop in the binary and
moves `exec_short` by 56 to 248 bytes:

| Source | Layouts | Cycles, quiet rounds |
|---|---|---:|
| E045 | as built, and three moved | 29.69 to 29.80 billion, every layout |
| E046 | as built, and six moved | 29.30 to 29.68 billion; the means of the seven are 29.40 to 29.58 |

Moving the code does not move the boot by more than the runs differ among themselves (0.6%
between the means of seven layouts), and E045 is slower than E046 in every layout, by about
1.2%. E046 is real; its twelve pairs said 1.9%, these say rather less. **A change under
about 0.6% of the boot cannot be told from a layout by pairs of one build each; a few padded
builds of each side can tell it**, and that is the instrument for the cards from here on.
(bench.bin is another matter: its two states are 25% apart and padding was not tried on
it.)

By the card: the splits by operand form are finished. Of E043's list what is left is the
fourth item, the memory operand itself (one comparison for page, crossing and RAM; a window
for the stack), each expected at about a point, which is now at the edge of what can be
measured; and, from E044, the 16-bit general path.

## E048: The Linux boot against rustx86 again, on one day (2026-11-16)

- **Hypothesis**: The comparison in E017's addendum is two days and thirty cards old: rustx86's
  interpreter 16.1 s and 257 billion host instructions, its JIT 11.4 s, g86m 27.3 s and then
  20.6 s. Main is now at about 165 billion host instructions and 30 billion cycles on the boot.
  Measured on one day from the same two files, g86m main reaches "busybox shell" in less time
  than rustx86's interpreter (by a third or more) and within 15% of rustx86 with its JIT.
- **What changed since last time**: g86m is main after E046 (b84b2be) and not the branch of
  E017; rustx86 is the same commit (64aba23), built again today. Both are given g86m's
  `images/vmlinuz-lts` and `images/initramfs-mini` (rustx86's own `initramfs-mini` is a
  different file; the kernel is the same). rustx86 is run through `jboot`, with
  `RUSTX86_JIT=0` and without; g86m with `--wait "busybox shell"`. Whole-process figures from
  `/usr/bin/time -l` for all three, seven rounds, interleaved.
- **Next move for each result**:
  - g86m ahead of the interpreter and within 15% of the JIT → the README and the talk say
    "behind in the fragment (E002, E019), ahead as a program, level with the JIT"; the next
    cards stay on E043's list
  - g86m ahead of the interpreter, more than 15% behind the JIT → say that the gap left is
    what a JIT buys, with its size; nothing in g86m's plan changes (Goose cannot call
    generated code)
  - g86m not ahead of the interpreter → the 165 billion is not what rustx86 is at today or the
    two runs do not do the same work; compare guest instruction counts and the serial output
    before saying anything
- **Cut-off**: The same day; seven rounds. If the serial output of the two does not reach the
  same line, the comparison is reported as not made.

### Result

2026-11-16, Apple M1, rustc 1.97.1, Goose v2026.4 with clang. **g86m is ahead of both: 43% less
time than rustx86's interpreter and 21% less than rustx86 with its JIT. The hypothesis had the
first and not the second; it expected the JIT level or ahead.** Seven rounds, the three runs
interleaved in each; medians, with the range of the seven. Time, host instructions and cycles
are for the whole process, from `/usr/bin/time -l`.

| | Guest instructions | Time | Host instructions | Per guest instruction | Cycles |
|---|---:|---:|---:|---:|---:|
| g86m main (b84b2be) | 1,647 million | 9.46 s (9.33 to 9.77) | 163.5 billion | 99 | 29.4 billion (29.2 to 29.9) |
| rustx86, interpreter (`RUSTX86_JIT=0`) | 1,500 million | 16.57 s (16.20 to 16.64) | 257.1 billion | 171 | 51.2 billion (50.8 to 51.5) |
| rustx86 with its JIT | 1,500 million | 11.95 s (11.81 to 12.61) | 176.2 billion | 117 | 37.0 billion (36.7 to 38.2) |

rustx86's figures are those of E017's addendum again (16.1 s, 257 billion, 171; 11.4 s with the
JIT), so the two days between did not move the instrument. Its JIT ran 58% of the guest
instructions as generated code in every round. Every g86m run printed the same 13,991 bytes and
stopped at 1,647,140,001 instructions; all fourteen rustx86 runs have the same instruction
count and serial checksum.

What the comparison is and is not:

- Both stop when "busybox shell" is in the serial output, from the same kernel and the same
  initramfs. `jboot` does not print the serial text, so that the two outputs are the same line
  for line was not checked; the stop is the same string.
- The guest instruction counts differ by 10% (rustx86 runs 256 instructions per timer tick,
  g86m 64, and rustx86 looks for the string every 10 million instructions). g86m does the
  larger count in the shorter time, so the difference does not favour it.
- The machine was not idle (load average about 3). The rounds fall into a quiet state and a
  busier one about 2% apart for all three; the order of the three is the same in every round.
- It is two programs, not two compilers. E002 and E019 are the comparison of the languages
  (the same fragment: Goose 35% slower as first written, within 7% with one change). Here
  g86m has had thirty cards of work on this boot since E017 and rustx86 has had none; rustx86
  was closed before that work.

By the card: none of the three branches named this one. The nearest is the first, and what is
to be said is "behind in the fragment, ahead as a program, and ahead of rustx86's JIT on this
boot". The next cards stay on E043's list.

## E049: What a run writes down after every instruction (2026-11-17)

- **Hypothesis**: Between two instructions of a run the loop stores five things and loads
  one: `cpu.ip` (at the start of the executor), `shadow`, `vtime`, `saved.ip` and
  `saved.flags` (with a load of `cpu.flags`). Three of the five are there only so that a
  fault can put the instruction pointer and the flags back, and one only for the first
  instruction of a run. If `cpu.ip` is stored after the executor and not before, it still
  holds the faulting instruction's own address when a fault comes, and `saved.ip` is not
  needed; if the few executors that set the flags before a store to memory put the old flags
  back around that store, `saved.flags` is not needed; `shadow` can only be set for the
  first instruction, and a run with it set is one instruction long, so it can be cleared
  where that run returns. That leaves two stores (`cpu.ip`, `vtime`): about 4 host
  instructions fewer for each guest instruction, **4% of the boot's host instructions and
  1% or more of its cycles** (a store is cheap; E047 saw 0.36% of the instructions buy
  nothing).
- **What changed since last time**: E023 and E026 to E029 shortened what the loop waits for
  (loads on the path to the next entry). This takes out stores nothing waits for, by changing
  who is responsible for a fault's undo: the executor, not the loop. Not tried before.
- **Next move for each result**:
  - Cycles down by 0.6% or more over padded builds of both sides → keep; the memory operand
    (E050) next, measured the same way
  - Host instructions down and cycles within 0.6% → keep only if every layout of the new
    source is at or under the old one's mean (a change that removes work and cannot be told
    from nothing is still less code in the loop); otherwise not kept
  - A test fails or the boot's count changes → an executor that changes the flags or
    `cpu.ip` before its last fault and is not on the list; find it with a wrong build of the
    one suspected
- **Cut-off**: The same day. `tools/difftest.sh`, test386, the boot's count; a test in which
  each executor that sets flags before a store faults on that store, and wrong builds that
  leave the old flags out; four padded layouts of each side, six rounds.

### Result

2026-11-17. **Kept: 4.2% fewer host instructions and about 1.7% fewer cycles, in every
layout. On the way: without a store on its taken path a conditional jump becomes a select,
and that alone costs 14%.** `tools/difftest.sh` has 82 lines, all ok (two of them new); the boot stops at
1,651,240,001 instructions as before.

**The first build was 14% slower with 4.3% fewer instructions.** It stored `cpu.ip` once,
after the executor, and so took `cpu.ip = nx - base` out of every executor, the conditional
jumps included. Putting the loop's stores back one at a time changed nothing (33.95 to 34.45
billion cycles against main's 29.7); aligning the CPU state changed nothing (see below); a
profile showed no one place, only the loads on the way to the next instruction all a little
heavier. What the slow builds had in common was the taken path of a conditional jump: with
nothing on it but `nx += imm`, the compiler makes a conditional select, the next
instruction's address is then data that waits for the flags, and the host cannot run ahead.
With the store back on the taken path only (it is live because the run no longer stores
`cpu.ip` itself) the same source is faster than main. **This is E031's hypothesis, and it was
right**: E031 added a store where there already was one, saw nothing move, and concluded the
jump was not what the loop waits on. It is; main had the branch by accident. The store now
has a comment that says why it is there.

**As kept.** A run notes where each instruction begins in `saved.ip` (as before) and leaves
`cpu.ip` behind until it ends or faults; `saved.flags` and the per-instruction store of
`shadow` are gone; the executors that set flags before a store to memory (ADC and SBB to
memory, the shifts and rotates, NEG, the 8-bit arithmetic, and the slow paths of the
read-modify-write helpers) have the old flags in place while they store. Per instruction the
loop now stores two things, `vtime` and `saved.ip`.

| Linux boot to the shell prompt | Host instructions | Cycles: median of six rounds, for each of four layouts |
|---|---:|---:|
| main | 164.1 billion | 29.38, 29.46, 29.55, 29.49 billion |
| E049 | 157.1 to 157.5 billion | 28.88, 28.87, 29.00, 29.06 billion |

The slowest layout of E049 is under the fastest of main. By the card: the first branch.

**Tests.** `s_flagro`: thirteen instructions, one for each executor that sets flags before a
store, each faulting on a read-only page after a CMP; the handler checks the flags in its
frame and the address the fault is reported against. `s_shadow`: a timer interrupt waiting
behind an STI is taken after exactly one more instruction. Seventeen wrong builds, each
caught: twelve that store with the new flags in place (one for each executor), `cpu.ip` not
set at a fault, at the end of a run, or when a run is out of time, `saved.ip` not noted, and
the shadow not cleared. Two of them passed at first: nothing looked at the address in a
fault's frame when the handler does not return to it, and nothing ran a short executor
behind an STI with an interrupt waiting.

**Found on the way: the CPU state is three bytes off alignment.** Goose packs globals with
no padding, and `cpu` begins at an address that is 3 modulo 4, so every guest register, the
flags, the TLB arrays and the rest of `state.goose` are loaded and stored unaligned, and the
compiler needs an extra instruction to form each address. One pad byte before `cpu`, on
main, in a build made only to be timed: 157.8 billion host instructions against 164.1, and
29.0 billion cycles against 29.65. That is the next card.

## E050: The globals back on their alignment, and a check that keeps them there (2026-11-17)

- **Hypothesis**: E017's addendum aligned the globals by declaring the widest first, for 2%
  of the boot's host instructions. Thirty cards have added globals since, and nothing shows
  where they landed. Read from the C the compiler generates (the globals are one packed
  struct; `offsetof` gives each one's place): `cpu`, `saved` and `seg_top` are at 7 modulo
  8; `ram`, the decode cache, `dc_next` and `code_mark` at 1; `vtime` at 2; `ins`, `ea_seg`,
  `ea_off` and `dc_cur` at 2; `chain_until` and `light_save` at 6; `timer_at` at 5. The TLB
  arrays and `cr` are aligned, by luck. For a field off its alignment the compiler forms the
  address with an extra instruction, and a load or store that straddles a 64-byte line costs
  the host more. One pad byte before `cpu` alone, on main, in a build made only to be timed
  (E049's result): 3.8% fewer host instructions and 2% fewer cycles, while it pushed the TLB
  arrays off their alignment. With every one of the globals above at a multiple of 8:
  **4% or more of the host instructions and 2% or more of the cycles**.
- **What changed since last time**: E015 tried eight paddings in front of the whole block
  and E017 reordered declarations, both without seeing the layout. This reads the layout,
  pads in front of each group that is off (a `u8` array of the size wanted), and adds a check
  to `tools/difftest.sh` that fails when a listed global is off its alignment, so that the
  next global added in front of them is noticed.
- **Next move for each result**:
  - Cycles down by 0.6% or more over padded code layouts of both sides → keep, with the check
  - Instructions down and cycles not → keep all the same if no layout is slower (it is E017's
    rule: the instruction count is the measure that repeats), and say so
  - bench.bin or test386 slower by more than their spread → some global of the 16-bit path is
    now off; find it with the layout tool before giving up a pad
- **Cut-off**: The same day. Pads only, no code: the tests must pass unchanged and the boot's
  count stay; four layouts of each side, six rounds; bench.bin and test386 timed too.

### Result

2026-11-17. **Kept: 3.7% fewer host instructions and about 3.4% fewer cycles on the boot, in
every layout; the 16-bit benchmark and test386 gain too.** Pads only: four `u8` arrays, 23
bytes in all. `tools/difftest.sh` has 83 lines, all ok (the new one is the layout check); the
boot's count is unchanged.

**The layout is not what the declarations suggest.** `tools/layout.sh` asks the C compiler
for `offsetof` each global in the struct the Goose compiler generates. The struct is packed,
but a growable array (`u8[>..]`) is a member aligned to 8, so alignment is restored behind
each one: `cr` and the TLB arrays were aligned because `tty` and `stop_message` are declared
just before them, and a pad in front of `cpu` moves nothing behind those two. The pads that
came out, after three rounds of build and look: 3 bytes before `timer_on`, 6 before `ins`, 4
before `chain_until`, 7 before `cpu`, 7 before `ram`, 6 before `vtime`. E049's trial with
one byte before `cpu` had the registers aligned and everything from `ram` on still off.

| | Host instructions | Cycles |
|---|---:|---:|
| Linux boot, E049, four code layouts | 157.2 billion | medians of six rounds: 29.31, 29.30, 29.31, 29.37 billion |
| Linux boot, E050, four code layouts | 151.4 billion | 28.34, 28.32, 28.30, 28.34 billion |
| bench.bin (16-bit), E049 | 97.91 billion | 14.61, 14.61, 14.62 billion |
| bench.bin, E050 | 91.35 billion | 14.33, 14.40, 14.33 billion |
| test386, E049 | 17.66 billion | 2.83, 2.85, 2.84 billion |
| test386, E050 | 16.93 billion | 2.77, 2.77, 2.76 billion |

(The machine was a little slower for this table than for E049's: E049 reads 29.3 here and
28.9 there. Each table's two sides were run interleaved.) By the card: the first branch.

**The check.** `tools/layout.sh --check` fails when one of twenty-one watched globals is off
its alignment, and `tools/difftest.sh` runs it; with the pad before `cpu` one byte short it
names `cpu`, `saved` and `seg_top`. It reads the compiler's generated C under `GOOSE_HOME`,
and is skipped where that is not to be found.

**What this says about earlier cards.** E015 called alignment "one extra instruction per
access, which turned out not to matter (1.5%)", and E017's addendum got 2% by reordering.
Both were right about the size then; the boot was 584 and 466 billion host instructions, and
the same extra instruction is a larger share of 157 billion. And both worked blind: E017's
order was undone by the globals added since, and nothing said so. From main at the start of
today (164.1 billion instructions, 29.4 to 29.7 billion cycles) the two cards together are
at 151.4 billion and 28.3 billion: **7.7% fewer instructions, about 4.5% fewer cycles.**

## E051: The memory operand's short path in fewer tests (2026-11-17)

- **Hypothesis**: E043's fourth candidate, the part of it that is a few lines. The short
  path of `seg_read`, `seg_write` and `rmw_place` tests, in order: the offset against
  `seg_top`; that the access does not cross a page; the TLB tag, at an index that includes a
  test of `cpu.cpl`; that the place is in RAM. Two of these can go. (1) Crossing: compare
  the tag with the page of the access's *last* byte. An entry at the index of the first
  byte's page can only hold a page with the same low eight bits, and the next page has
  others, so an access that crosses never matches (Bochs and QEMU take the tag from the last
  byte for this). (2) The privilege level: the index's ninth bit kept in a global, set where
  the level changes, in place of a load of a byte, a comparison and a select at every
  access. The test for RAM stays: it is what takes the bounds checks off the four loads. By
  E037's rate (3.6% of the instructions gave 1.8% of the cycles): about 5 host instructions
  for each of the accesses, which are about one for every two guest instructions, **1.5% of
  the host instructions and under 1% of the cycles**.
- **What changed since last time**: E037 made the segment test one bound; this is the same
  kind of change on the next two tests. Measured with padded layouts (E047's instrument),
  which E037 did not have.
- **Next move for each result**:
  - Cycles down by 0.6% or more, or instructions down and no layout slower → keep; then the
    stack window is the last of E043's list, and it is decided by a count of what a PUSH and
    a POP still cost after this
  - No layout faster and some slower → not kept; the tests were predicted and free
  - A test fails → a place where the level changes without the global following (a fault
    that puts the CPU state back; the boot protocol's entry), or an access that crosses
- **Cut-off**: The same day; `tools/difftest.sh`, the boot's count, wrong builds (the tag
  from the first byte in each of the three places; the global not following a change of
  level, and not following a fault's undo), four layouts of each side, six rounds.

### Result

2026-11-17. **Not kept: 0.75% fewer host instructions and about 0.5% more cycles, in every
layout; each half alone is slower too.** `src/` is as it was after E050. The two tests
written for it stay, because what they check is true of the code as it is.

| Linux boot to the shell prompt | Host instructions | Cycles: median of six rounds, for each of four layouts |
|---|---:|---:|
| E050 | 151.4 to 151.6 billion | 28.31, 28.50, 28.32, 28.35 billion |
| E051 | 150.3 to 150.5 billion | 28.46, 28.46, 28.63, 28.49 billion |

The fastest run of each layout says the same: 28.12 to 28.21 against 28.26 to 28.36. Then
each half by itself, one layout, six rounds:

| | Host instructions | Cycles, median |
|---|---:|---:|
| E050 | 151.38 billion | 28.37 billion |
| The tag from the last byte only | 150.24 billion | 28.50 billion |
| The level in a global only | 151.35 billion | 28.66 billion |
| Both (E051) | 150.23 billion | 28.66 billion |

All of the instructions saved are the crossing test's, and taking it out costs cycles: the
test was a branch the host predicted, off the path to the load, and what replaced it is an
addition on the way to the tag comparison. The global for the level saves nothing (a load
in place of a load, a comparison and a select) and costs 1%; why was not looked into. By the
card: the second branch, and "the tests were predicted and free" is the reading.

**What this closes.** The stack window is not tried. Its whole gain would be tests of the
same kind taken off PUSH and POP (the segment bound, the crossing, the tag), and this card
says those tests cost nothing where they are; it would add a cached translation to keep
true across every flush for that. That was the last item of E043's list. The 16-bit general
path (E044) is not tried again either: nine formulations were measured there, and E050 has
since given bench.bin 2% of its cycles back from another side.

**Tests kept.** `s_pagecross`: loads, stores and an ADD that cross from a page into the
next, where the two are not next to each other in RAM, checked against loads that do not
cross; three wrong builds (the tag taken from the first byte in `seg_read`, `seg_write` and
`rmw_place`) fail it and passed everything before it. `s_modeundo`: a far return to ring 3
that faults after CS is loaded, then a store from ring 3 into the page of ring 0's stack; a
wrong build that did not put the level's global back failed only this, and only once the
test aimed at the pushes of the fault's own delivery (every later change of level repairs
the global, so the window is those three pushes).

## E052: What still takes the general path (2026-11-17)

- **Hypothesis**: E040 counted 49.7 million runs in a boot, each ended by a trip through the
  general path at 39 cycles of entry before the instruction itself, and 12.9 million of them
  ended by an instruction with no executor. E042 has since taken away most of the ends at a
  page of code, so what ends a run now is mostly such an instruction, and each one costs its
  own general execution, the entry, and the start of a new run. E025 was the last card to
  ask which instructions these are, twenty-seven cards ago. If a handful of opcodes make up
  most of them, executors for those are worth a card; if they are spread over the opcode
  map, this line of work is finished. A count by opcode (with the operand-size prefix and
  REP told apart) of every instruction of 32-bit code that the general path executes in a
  boot, and of how many times it is entered at all.
- **What changed since last time**: E025 chose from a count made before runs crossed pages,
  before the string executors and before the code-write change. Nothing has counted since.
- **Next move for each result**:
  - A few opcodes (five or fewer) are 60% or more of the general path's instructions, and
    those are 1% or more of all guest instructions → executors for them, next card, sized at
    the count times 40 cycles
  - Spread out, or under 1% of all instructions → no card; the optimizations that can be
    done without changing the unit of execution are done, and the next one is the fusion of
    pairs or nothing
- **Cut-off**: The same day; one counting build, one boot. The counting build is a copy and
  `src/` is not touched.

### Result

2026-11-17. **Spread out, and small: no card.** One counting build (a copy; `src/` untouched),
one boot, the same 1,651,240,001 instructions.

- The general path is entered 24.7 million times in a boot (49.7 million in E040, before runs
  crossed pages). 1.0 million of those run a short executor singly, and 23.8 million execute
  an instruction of 32-bit code the long way: **1.44% of all guest instructions**.
- No opcode stands out. The first five are 30% of them and it takes nineteen to reach 60%:

  | Opcode | Times | Share of the general path's instructions | Share of all |
  |---|---:|---:|---:|
  | A1 (`mov eax, [addr]`) | 2.11 million | 8.9% | 0.13% |
  | 89 (`mov r/m, r`) | 1.91 million | 8.0% | 0.12% |
  | 8B (`mov r, r/m`) | 1.26 million | 5.3% | 0.08% |
  | FF (the group: indirect CALL and JMP, PUSH) | 1.01 million | 4.2% | 0.06% |
  | 83 with a 16-bit operand | 0.93 million | 3.9% | 0.06% |
  | C9 (LEAVE), F7, 31, 96 (XCHG), REPE CMPSB, 8D, 6A, C7, 9C (PUSHF), 0F B1 (CMPXCHG), ... | 0.2 to 0.8 million each | under 3.5% each | under 0.05% each |

  Several in the list have executors (89, 8B, 31, 8D): those are first executions, which
  always go the long way, and forms the executors leave out (a segment override, 16-bit
  addressing).
- At E040's 39 cycles an entry, all 24.7 million entries are 1.0 billion cycles, 3.4% of the
  boot, and the largest single opcode is a tenth of that.

By the card: the second branch. **What can be done without changing the unit of execution
is done.** Today's three cards against main at the start of the day:

| Linux boot to the shell prompt | Host instructions | Cycles |
|---|---:|---:|
| Main this morning (E046) | 164.1 billion | 29.4 to 29.7 billion |
| After E049 and E050 | 151.4 billion | 28.3 to 28.5 billion |

What is left is the fusion of pairs (a compare and the conditional jump after it as one
executor), which changes what a run counts, notes and undoes; E049's finding belongs to its
card, because a fused pair has to stay a branch on its taken path for the same reason.

`tools/difftest.sh` on the source as it stands has 87 lines, all ok (four self-checks more
than this morning, each run on the debug and the release build, and the layout check).

## E053: Which pairs of instructions follow each other in a run (2026-11-17)

- **Hypothesis**: A NOP in a row costs 10 cycles and a `mov` 17 to 20 (E031, E040): about
  half of an instruction is the loop, not the executor. An executor for two instructions
  pays the loop once. The first candidates are a flag-setting instruction and the
  conditional jump after it: conditional jumps are 11.7% of the boot's instructions (E040),
  the jump's entry is always the one after the compare's, and a fused pair can branch on the
  comparison itself. Whether that is worth building depends on how the pairs are spread: if
  the instruction before a conditional jump is one of a few kinds (CMP and TEST in their
  register and immediate forms), six or fewer pairs cover most of the jumps; if it is any of
  thirty, each pair is too rare to pay for its executor. A count, over a boot, of every
  (kind, next kind) that a run executes one after the other.
- **What changed since last time**: E024 and E043 rejected linking and traces from other
  emulators' figures; nothing has counted pairs in g86m. E047 warns that more kinds can move
  the compiler's code for the whole loop, so the count has to promise more than a point.
- **Next move for each result**:
  - Six or fewer pairs ending in a conditional jump cover 6% or more of all instructions →
    a build made only to be timed that fuses the commonest one, to learn what a fused pair
    saves in cycles; then the card for the fusion itself
  - The jumps' predecessors are spread (the top six under 4%) → look at the commonest pairs
    of any kind (two MOVs, PUSH and PUSH); if those are under 4% too, fusion is not built
- **Cut-off**: The same day; one counting build (a copy), one boot.

### Result

2026-11-17. **Five pairs ending in a conditional jump are 7.8% of all instructions, and a
fused pair saves about 49 host instructions; but the first four ways of building it lost
more in the loop than the pairs gave.** The count, one boot of a counting copy:

| Before a conditional jump | Share of all instructions |
|---|---:|
| CMP `r/m, r` | 3.24% |
| CMP `r/m, imm` | 1.47% |
| TEST `r/m, r` | 1.22% |
| TEST `r/m8, imm8` | 1.01% |
| TEST `r/m8, r8` | 0.88% |
| the 8-bit arithmetic with an immediate, DEC, the others | 0.66%, 0.47%, under 0.45% each |

Conditional jumps are 11.75% of all instructions, 98.4% of all instructions are executed in
runs, and nearly every jump is of the kind that tests a mask of flags. By the card: the
first branch (six pairs, 8.4%). Of pairs of any kind the commonest are a conditional jump
and the `mov` after it (3.25%), which is not a pair in the code (the jump may be taken), and
two `mov`s from memory (2.9%).

**The builds made to be timed** fused CMP `r/m, r` and its jump first, then all five. What
each one cost the instructions that are not pairs is the finding:

| How the run learns that an executor ran two instructions | Linux boot, host instructions | |
|---|---:|---|
| main | 151.4 billion | |
| The kind is changed before the dispatch when there is time for one only | 172.1 billion | the compiler split the dispatch into two jump tables |
| A flag worked out before every dispatch and passed to the executor | 161.5 billion | four instructions before every dispatch, and a register short |
| The executor returns two values | 158.9 billion | an inline function that returns two values gets a test of the fault flag after it, every time |
| The count in the upper half of a 64-bit return value (one pair; five pairs) | 154.2; 150.6 billion | one constant to set before every dispatch, and the loop's end test no longer joined to its subtraction |
| A mark above the address, found where the run tests the address anyway | 151.3 billion | no better: the loop was out of registers |
| The same, and the run counts with one counter in place of two | **146.6 billion** | |

A pair saves 49 host instructions (from the difference between one pair and five), so 128
million pairs are 6.3 billion, 4.1% of the boot; the builds that did worse than main were
paying three to thirteen instructions on each of 1.5 billion dispatches. The loop of
`exec_short` had no register to spare (`pbase` and `off_max` already live on the stack), and
each of these designs asked for one more. What made room was not in the pairs at all: the
run kept two counters that move together, the virtual time and the instructions left, and
now keeps one (the time is put right when the run ends). The next card is the fusion as
built on that.

## E054: A compare and the conditional jump after it as one executor (2026-11-17)

- **Hypothesis**: With the design E053 ended on, the five pairs save 49 host instructions
  each on 128 million pairs and cost the other executors nothing: **3% of the boot's host
  instructions and 1.5% or more of its cycles** (the cycles of a loop trip that is not made
  are mostly off the path the host waits on, so less than the instructions).
- **What changed since last time**: E053's last timing build, made into the real thing.
  - `classify` looks at the bytes after a CMP `r/m, r`, CMP `r/m, imm`, TEST `r/m, r`, TEST
    `r/m8, imm8` or TEST `r/m8, r8`; if they are a conditional jump with no prefix, the
    entry becomes a pair: its next address is the one after the jump, and the jump's
    condition and offset go into the entry's `bytes`, which a 32-bit entry has not used
    since E044. The pair is at most 14 bytes, inside the 15 that a store into code looks
    back over and inside the 16 that an entry has before its page ends.
  - A pair counts as two instructions. A run now stops one instruction short of the time it
    has, and the instruction it stops at is the general path's, so a pair is run only when
    there is time for two and the run can never go past its limit; with time for one, and
    from the general path, the executor runs the first instruction alone. The executor says
    that it ran both with a bit above the 32-bit address it returns, and the run finds the
    bit where it already tests whether the address is on the page.
  - The run counts with one counter: `run_left`, stored after each instruction; the virtual
    time stands still during a run and is put right at its end, after a fault, and for RDTSC.
  - `exec_short` no longer returns a value: it never ends a step.
- **Next move for each result**:
  - Cycles down by 0.6% or more over padded layouts → keep; then count again what precedes
    the jumps that are left (the 8-bit arithmetic, DEC) and what a jump is followed by
  - Instructions down, cycles within 0.6% → keep if no layout is slower, and stop there
  - A test fails or the boot's count changes → the count of a pair, or the stop one short
- **Cut-off**: The same day. `tools/difftest.sh`; the boot's count; `s_pairs` (every
  condition, each kind of pair, a near jump, the jump rewritten in place), `s_pairfault` (a
  fault in a pair's first instruction; the time across pairs, by RDTSC), a stop after each of
  400 instruction counts compared with the trace; wrong builds; four layouts, six rounds.

### Result

2026-11-17. **Kept: 3.2% fewer host instructions and about 1.5% fewer cycles on the boot, in
every layout.** `tools/difftest.sh` has 93 lines, all ok; the boot stops at 1,651,240,001
instructions as before; test386 byte for byte.

| Linux boot to the shell prompt | Host instructions | Cycles: median of six rounds, for each of four layouts |
|---|---:|---:|
| main (E050) | 151.4 billion | 28.30, 28.26, 28.36, 28.42 billion |
| E054 | 146.5 billion | 27.92, 27.88, 27.98, 27.86 billion |
| E054 with `classify` making no pairs (one layout) | 150.3 billion | 28.61 billion |

The slowest layout of E054 is under the fastest of main. The third row is the new loop
without what it was built for: 0.8% fewer instructions than main and **1% more cycles**, so
against its own loop the fusion is worth 2.5% of the instructions and 2.4% of the cycles,
and the loop as rebuilt gives a point of that back. Where that point goes was not looked
for (candidates: the address test in 64 bits against two values on the stack; the copy of
the address into the register the executors return in). bench.bin and test386, which run no
pairs: 92.1 against 91.4 billion instructions and 14.3 against 14.5 billion cycles; 17.0
against 16.9 and 2.80 against 2.80.

By the card: the first branch.

**Tests.** `s_pairs`: CMP `r/m, r` with all sixteen conditions and the other four pairs with
two each, a near jump after a CMP from memory, and that jump's condition rewritten in place
half way; the sum expected is a trace run's, which goes one instruction at a time and makes
no pairs. `s_pairfault`: a pair of each kind whose first instruction faults (address and
flags in the handler's frame), and RDTSC round the whole of it, against a trace run's count.
And in `tools/difftest.sh`, `s_pairs` stopped after each of 400 instruction counts, where
it must be at the address the trace has for that count.

Seventeen wrong builds, each caught: three in how a condition is kept (L and GE swapped, LE
without ZF, SF xor OF left out), two in reading the jump (offset not sign-extended, the
condition from the wrong byte), a pair run with time for one, the lone instruction's next
address, a pair counted once, the mark not seen, four pairs with the wrong first instruction,
the time not put right after a fault or at a run's end, RDTSC without the run's count, and a
run that goes on to its limit. Three passed at first. Two were the test's: `test al, 4` is
assembled in the short form for AL, which is not one of the pairs, so that pair was never
run; and an 8-bit TEST of the whole register gives the same flags as of its low byte, until
the register is DH. The third (a pair with time for one) is what the stops are for, and they
catch it, as they do the run that goes on to its limit; nothing else does.

**What the day's cards add up to**, Linux boot to the shell prompt:

| | Host instructions | Cycles |
|---|---:|---:|
| Main this morning (E046) | 164.1 billion | 29.4 to 29.7 billion |
| After E049 and E050 | 151.4 billion | 28.3 to 28.5 billion |
| After E054 | 146.5 billion | 27.9 to 28.0 billion |

Next, by the card: a count of what precedes the conditional jumps that are still by
themselves, and what the rebuilt loop lost.

## E055: What is left to fuse, counted on the fused build (2026-11-17)

- **Hypothesis**: E054's card asked for this count. After the five pairs, the conditional
  jumps still on their own are 4% of all instructions, and E053's table says what precedes
  them is spread thin (the 8-bit arithmetic 0.66%, DEC 0.47%, ...). If six more pairs cover
  2.5%, at 49 host instructions a pair that is 0.8% of the boot's instructions and under
  half a percent of its cycles: by itself below what can be measured. The same count shows
  the pairs that do not end in a jump, where the larger numbers are.
- **What changed since last time**: E053's count was of main before any pair; this is of
  main with the five.
- **Next move for each result**:
  - Some predecessor of a lone jump is 1% or more → a pair for it
  - None is, and the six largest together are 2% or more → one card for the six together,
    kept only if the instructions fall and no layout is slower
  - Pairs without a jump: listed for a card of their own; a pair whose second instruction
    can fault needs the run's count and the instruction pointer moved on between the two,
    which the jump pairs did not
- **Cut-off**: The same day; one counting copy, one boot.

### Result

2026-11-17. **No predecessor of a lone jump reaches 1%; the six largest are 2.5%. The large
pairs are those that begin with `mov r, r/m`.** One boot of a counting copy; 1,496 million
dispatches for the 1,651 million instructions.

| Before a conditional jump that is still alone (3.94% of all instructions) | Share of all |
|---|---:|
| 8-bit arithmetic `r/m8, imm8` | 0.66% |
| DEC of a register | 0.47% |
| ADC or SBB `r/m, r` | 0.44% |
| DEC `r/m` | 0.43% |
| `mov r/m, r` (the flags are older) | 0.28% |
| 8-bit arithmetic on AL, AND `r/m, imm`, TEST `r/m, imm32`, SUB `r/m, imm` | 0.24%, 0.22%, 0.18%, 0.16% |

| Pairs of any kind | Share of all |
|---|---:|
| `mov r, r/m` then `mov r, r/m` | 2.93% |
| `mov r/m, r` then `mov r, r/m` | 2.10% |
| `mov r, r/m` then a CMP-and-jump pair | 1.72% |
| `mov r, r/m` then `mov r/m, r` | 1.47% |
| `mov r, r/m` then `mov` between registers | 1.25% |
| `mov r, r/m` then ADD `r/m, r` | 1.12% |
| IMUL then IMUL; `mov` between registers then `mov r, r/m`; a shift by CL then SUB | 0.99%, 0.98%, 0.96% |

`mov r, r/m` is 13.4% of all instructions, and what follows it is one of six kinds for
9.4%. By the card: the second branch for the jumps (one card for the six together), and the
`mov` pairs go to a card of their own, with the note above: the second `mov` can take a
page fault after the first has written its register.

## E056: The point the rebuilt loop lost (2026-11-17)

- **Hypothesis**: E054's loop with no pairs made is 1% slower in cycles than main's was, with
  0.8% fewer instructions. Read side by side, the two tails are the same length; what the
  new one has that the old did not is a copy of the next address into the register the
  executors return in (`pr` beside `p`), the address test in 64 bits, and it still carries
  `ran`, a flag set to true after every instruction for the one use at the end of the run.
  The loop is out of registers (E053), so a variable less is worth more than its own
  instruction. Two changes, each by itself and together: (A) one loop variable for the
  address, `pr`, with `p` its lower half taken where it is used; (C) no `ran`: whether the
  run executed anything is `left` against what it started as.
- **What changed since last time**: E053 tried (A) together with a second copy of the stores
  at the loop's exit and got a loop full of spills; this is (A) alone. (C) is new.
- **Next move for each result**:
  - Either gives fewer host instructions and, over padded layouts, cycles at or under
    E054's → keep it
  - Neither moves the instructions by 0.3% → not kept, and the point is left: two
    formulations are the limit for this (E044 spent nine on the like)
- **Cut-off**: The same day; three builds, host instructions first, then four layouts of
  whatever is kept.

### Result

2026-11-17. **Not kept: neither change, nor both.** `src/` is as it was.

| Linux boot | Host instructions | Cycles, one run |
|---|---:|---:|
| main (E054) | 146.51 billion | 27.81 billion |
| (A) one loop variable for the address | 166.29 billion | 30.80 billion |
| (C) no `ran` | 146.60 billion | 28.47 billion |
| both | 147.40 billion | 28.75 billion |

(A) by itself does what it did in E053: the compiler keeps five of the loop's values on the
stack and reloads them on every trip. (C) takes away a constant set on every trip and the
instruction count goes up all the same. By the card: the second branch; two formulations
were the limit, and the point is left where it is. What the three builds say together is
that this loop's code is decided by the register allocator more than by the source, and
that a change is only known by building it.

## E057: Seven more pairs that end in a conditional jump (2026-11-17)

- **Hypothesis**: E055's second branch. DEC of a register, DEC `r/m`, the 8-bit arithmetic
  with an immediate (on `r/m8` and on AL), AND and SUB `r/m, imm`, and TEST `r/m, imm32`,
  each with the conditional jump after it: 2.4% of all instructions between them, 39 million
  pairs. At 49 host instructions a pair, 1.9 billion, **1.3% of the boot's host instructions
  and about half a percent of its cycles**. Each is one arm that does what the lone executor
  does and then `pair_end`; nothing in the run changes.
- **What changed since last time**: E054 fused five instructions that only set flags. These
  seven (all but TEST) also write a result, some to memory, where the store can fault after
  the flags are worked out; the lone executors already have the old flags in place for that
  store (E049), and the jump is not reached.
- **Next move for each result**:
  - Host instructions down by 1% or more and no layout slower in cycles → keep
  - Instructions down and some layout slower, or the instructions up (seven arms more can
    move the loop's code, E047) → not kept, and no more pairs of this size
- **Cut-off**: The same day. `s_pairs` with a pair of each new kind; `s_flagro` with a jump
  after two of its faulting stores; wrong builds; four layouts, six rounds.

### Result

2026-11-17. **Kept, on E017's rule and not on this card's figure: 0.6% fewer host
instructions, about 0.4% fewer cycles, and no layout slower.** `tools/difftest.sh` 93 lines,
all ok; the boot's count unchanged.

| Linux boot to the shell prompt | Host instructions | Cycles: median of six rounds, for each of four layouts |
|---|---:|---:|
| main (E054) | 146.5 billion | 27.73, 27.68, 27.66, 27.62 billion |
| E057 | 145.6 billion | 27.63, 27.52, 27.48, 27.61 billion |

The card said 1.3% of the instructions and asked for 1%; it got 0.6%, 0.88 billion for 39
million pairs, **22 host instructions a pair where E054's saved 49**. The difference was not
looked into; the likeliest part of it is that E054's five first instructions are among the
shortest executors, so that the loop's share of them was largest, and that these seven had
a jump of the masked kind after them already. The card's two branches did not provide for
"fewer instructions than asked, and nothing slower"; it is kept because every layout is at
or under its counterpart and the instruction count, which repeats, fell (E017's addendum).
In cycles it is at the edge of what four layouts can show (0.4%, where the layouts of one
source differ by 0.1 to 0.2%).

By the card's second half: **no more pairs of this size.** What is left before a lone jump
is under 0.3% each.

**Tests.** `s_pairs` has a pair of each new kind (and one for arithmetic on AL that stores
its result, one for DEC of memory); `s_flagro` has a jump after two of its faulting stores,
so that a pair whose first instruction faults on its store is checked for flags and
address. Nine wrong builds, each caught; two passed at first (the AL pair in the test was a
CMP, which stores nothing; TEST with an immediate was told from CMP only by test386).

## E058: Goose calls code it generated (2026-11-17)

- **Hypothesis**: "Goose cannot call generated code" (E048) is true of Goose by itself: it has
  no function pointers. It can call C (`extern fn`, `c_sources`), and C can map memory that
  may be executed and jump to it. So a few lines of C are enough for a Goose program to
  write arm64 instructions into a buffer and run them: one function that maps the memory,
  one that copies bytes into it (on macOS a thread must switch the mapping between writable
  and executable, and the instruction cache has to be told), one that calls an address with
  a pointer to the guest state. What decides whether a JIT for g86m is worth designing is
  what such a call costs. A run of the interpreter executes about 32 guest instructions at
  18 cycles each; if entering generated code costs under 20 cycles, a block of a few
  instructions already pays, and if it costs hundreds (a slice passed by value, a wrapper
  that saves every register) only long blocks would.
- **What changed since last time**: Nothing in g86m generates code. This uses the one new
  thing the project allows itself here: executable memory through a C extension. The dull
  alternative is what g86m is now (an interpreter with fused pairs, E054); it is not given
  up, and the probe is a separate program under `probe/`.
- **Next move for each result**:
  - It runs, and a call costs under 20 cycles → a card for the design: what a block is, how
    generated code reaches the guest's registers and RAM, and how it leaves when an
    instruction would fault (it cannot use Goose's return out of `exec_one`)
  - It runs, and a call costs 20 to 200 cycles → the design has to chain blocks inside the
    generated code so as to leave it seldom; say so in the design card
  - It cannot be made to run (the mapping is refused, or Goose cannot hand the state's
    address to C) → reported as not possible on this machine, with what refused
- **Cut-off**: The same day. A stub that adds one to a guest register, called 100 million
  times, against the same loop in Goose; and a generated loop that does it 100 million times
  in one call.

### Result

2026-11-17. **It runs, and a call costs about 8 cycles.** `probe/jit0.goose` writes two
functions as arm64 instructions into a Goose array, `probe/jit0.c` (three functions, about
thirty lines) maps memory with `MAP_JIT`, copies them in and calls them:

| | 100 million times | Each |
|---|---:|---:|
| A generated stub (add one to a guest register in memory), called from Goose through C | 242 ms | 2.4 ns, about 8 cycles |
| The same addition as a generated loop, in one call | 32 ms | 0.3 ns, one cycle |

(The same loop written in Goose took no time: the compiler worked the sum out.) The state
crosses as a slice, whose data pointer is the address of the guest's registers; nothing
refused. By the card: the first branch. A call is less than half of one interpreted
instruction, so a block does not have to be long to pay, and leaving generated code often
is affordable; the design card is next.

## E059: A JIT, first stage: blocks of instructions that touch no memory (2026-11-17)

This card is the design as well as the first experiment. The stages after it are cards of
their own.

**Why generated code, and what the dull alternative is.** The interpreter is at 88 host
instructions for a guest instruction, and E052 and E056 say what is left in it comes a
fraction of a percent at a time. Generated code has no dispatch, no entry to look up, keeps
the guest's registers in host registers and works the flags out only where something reads
them. It is the one new technique this project takes on beside Goose itself; the interpreter
stays whole and stays the default, and `--jit` turns the rest on.

**The unit.** A block: instructions of 32-bit code that follow one another in one physical
page, from the target of a jump to the next jump (included) or to the first instruction the
translator does not know (excluded). It is found through the decode cache, whose entries say
what each instruction is; nothing is decoded twice.

**How it is entered.** The entry of a block's first instruction gets the kind `K_BLOCK`, and
its own kind is kept beside it. The run dispatches it like any executor; the executor calls
the generated code through C and gets back the next address and how many instructions ran,
which the run counts where it counts a pair's second (E054). A block runs whole or not at
all: it is given the run's time and the highest address the run may execute at, and if
either is short it does nothing, and the general path runs its first instruction by its own
kind.

**What generated code may do.** It reads and writes the guest's registers and flags, and
nothing else in this stage. It never faults and never calls back, so Goose's return out of
`exec_one` does not have to cross it. The stage after this one adds memory operands the same
way: the fast path inline, and for anything else the block stops before that instruction
and the interpreter takes it.

**Flags.** The translator knows which instruction set the flags last. The generated code
keeps that instruction's operands and result in three host registers; a conditional jump at
the block's end redoes the comparison on them with the host's own flags, and EFLAGS is
written out only where the block is left.

**When a block is made.** Each jump counts arrivals at its target; at the eighth, the
block is translated.

**When a block dies.** A store into a page that has decode-cache entries already goes the
long way (E044); it now also moves the page's generation on, and a block made under another
generation is dropped when it is next reached.

- **Hypothesis**: The machinery above can be built in Goose with about forty lines of C, and
  with `--jit` every test passes and the Linux boot stops at the same 1,651,240,001
  instructions. Blocks without memory operands are short, so this stage is not expected to
  be faster: the boot's cycles within 3% of the interpreter's either way, and a count of how
  many instructions run in blocks (expected 10 to 20%).
- **What changed since last time**: E058 showed the call. This is the first generated code
  that executes guest instructions.
- **Next move for each result**:
  - Everything passes with `--jit`, the count is the same → the second stage: memory
    operands with an exit to the interpreter, which is where the speed is
  - A test fails only with `--jit` → the block's first wrong instruction, found by halving
    the set of kinds the translator accepts
  - Without `--jit` the boot is slower by 0.6% or more (the jumps now count arrivals) → the
    counting moves out of the jump executors before anything else
- **Cut-off**: This stage ends when the suite passes with and without `--jit`, or at three
  wrong instructions that halving cannot find.

### Result

2026-11-17. **It works: with `--jit` every test passes and the Linux boot stops at the same
1,651,240,001 instructions, 11.3% of them run in generated code. With it the boot is 0.7%
faster than main; without it, the same source is 1.1% slower than main, which is over this
card's line.** `tools/difftest.sh` has 97 lines, all ok, four of them with the JIT.

| Linux boot to the shell prompt | Host instructions | Cycles: median of six rounds, for each of three layouts |
|---|---:|---:|
| main (E057) | 145.6 billion | 27.35, 27.52, 27.41 billion |
| This source, without `--jit` | 142.7 to 142.8 billion | 28.01, 27.52, 27.69 billion |
| This source, with `--jit` | 144.0 to 144.1 billion | 27.48, 26.96, 27.30 billion |

With `--jit`: 6,631 blocks, 1.15 MB of code, 186.8 million guest instructions in blocks.
test386 with `--jit` is byte for byte the reference.

**What was built.** `src/jit.c`, forty lines: map, copy, call. `src/jit.goose`, the
translator: an emitter for the arm64 instructions it uses, the flags (the last
flag-setting instruction's operands and result in three host registers; EFLAGS written out
where a block is left; a conditional jump redoes the comparison with the host's flags, and
where the condition cannot be had that way the block ends before the jump), and blocks of
MOV between registers and of an immediate, LEA, the arithmetic and TEST between registers
and with an immediate, INC and DEC, ending at a JMP, a conditional jump or a fused pair.
A block is entered where the run finds a kind with no executor, so the interpreter's own
path is not touched; it is counted there, and where it cannot run (the page was written
since, or there is not the time or the room for all of it) its first instruction is run by
its own kind.

**Three designs of the entry, as in E053.** A `K_BLOCK` executor among the others, the
count returned beside the address, and arrivals counted by the jump executors: 151.1
billion host instructions without `--jit`, 3.8% over main. Taking the counting out of the
jumps: 150.6. Undoing the three changes to the run one at a time: each was worth one to two
billion, none was the culprit. Finding blocks where the run finds a kind with no executor
(the branch is there already): 142.8 billion, under main. Arrivals are now counted where a
run begins and where a block ends, which is less often and finds fewer blocks to start
with; that is the stage's 11%.

**The line this card set, and where it is.** "Without `--jit` slower by 0.6% or more: the
counting moves out of the jump executors before anything else." That was done, and the
instruction count is 1.9% under main's; the cycles are 0 to 2.4% over, by layout, 1.1% on
average, and the layouts of this source differ among themselves by 1.8% where main's
differ by 0.6%. The run's function is larger by the block's branch and its code has moved;
E056 is the precedent for not chasing that by reformulation. It stands as an open cost of
having the JIT in the source, to be weighed when the second stage says what the JIT gives.

**Tests.** `s_jit`: thirty-odd blocks, one for each instruction the translator knows and
each way a conditional jump is taken from a block's own flags, EFLAGS and the result summed
against a trace run; INC after SUB in one block; a block changed in place too far from its
first instruction for the store to empty that entry. `s_cslimit` now makes a block that
runs past the segment's limit, which must not be run. Twenty-two wrong translators, each
caught. Four passed at first, and one of those for a reason worth keeping: the changed
instruction's result differed in bit 30 in four places of the sum, and the sum, which
multiplies by three between terms, cancelled them exactly. The change is now in the low
bits.

By the card: the first branch. The second stage is memory operands: the fast path of
`seg_read` and `seg_write` generated inline, and a block that leaves, with the state as the
interpreter needs it, before an instruction whose operand is not on that path.
