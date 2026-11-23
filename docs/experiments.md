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

## E060: Why the JIT's source is slower with the JIT off (2026-11-17)

- **Hypothesis**: E059 left the same source 1.1% slower than main without `--jit`, with 1.9%
  fewer host instructions. Fewer instructions and more cycles is the sign E049 and E053 both
  met. Read in the disassembly of the two builds: main's `exec_short` has one indirect jump,
  the dispatch; the JIT source's has two, with a test of the kind against 32 in front. The
  compiler has split the dispatch into two jump tables. E053 met exactly this and named the
  cause: the value a `match` is on is changed just before the `match`. E059 does that where
  a block cannot run: `kind = jit_kind[...]`, then on to the dispatch. If that assignment
  goes (the run ends there instead, and the general path, which already runs a block's first
  instruction by its own kind, takes it), the dispatch is one table again and the cycles are
  main's.
- **What changed since last time**: E059 measured the cost and did not look for it. This
  reads the code first; the cause it proposes is one this ledger has already recorded.
- **Next move for each result**:
  - One indirect jump again, and without `--jit` the cycles are within 0.6% of main's over
    padded layouts → keep; the JIT's source no longer costs the interpreter anything
  - One indirect jump and still slower → the split was not it; next the store of
    `run_pmax` and the test of `jit_on` where a run begins, one at a time
  - Still two → something else changes the kind before the dispatch; read the function again
- **Cut-off**: The same day; the disassembly first, then three layouts of each, six rounds.
  With `--jit` the suite and the boot's count as before.

### Result

2026-11-17. **Found, in two parts, and fixed: without `--jit` the source is as fast as main
again. The price is on the other side: with `--jit` this stage is now 5% slower than main,
because leaving the run for each short block costs more than the block saves.**
`tools/difftest.sh` has 99 lines, all ok.

| Linux boot to the shell prompt, without `--jit` | Host instructions | Cycles: median of six rounds, for each of three layouts |
|---|---:|---:|
| main (E057) | 145.6 billion | 27.79, 27.59, 27.72 billion |
| E059 as committed | 142.7 billion | 28.01, 27.52, 27.69 billion (its own rounds; main then read 27.35 to 27.52) |
| E060 | 146.7 billion | 27.78, 27.70, 27.74 billion |

The mean of E060's three layouts is 0.1% over main's, and the layouts agree with each other
again (0.3% apart, where E059's were 1.8% apart).

**Part one: the dispatch was in two jump tables.** As the card read it from the
disassembly, and for the reason E053 recorded: where a block could not run, E059 set `kind`
to the entry's own kind and went on to the dispatch. With the run ending there instead,
`exec_short` has one indirect jump again and the instruction count is main's. The cycles
were not: 27.94 billion in every layout against main's 27.34, 2.2% more with the same
instructions. By the card's second branch the store of `run_pmax` and the test of `jit_on`
were taken out one at a time, and neither was it (27.87, 27.89).

**Part two: the code that runs a block was in `exec_short`.** Taking the block's branch out
altogether gave main's cycles (27.33). So the branch was put back in pieces:

| What `exec_short` does when it meets a block | Cycles without `--jit` (main 27.4 to 27.5) |
|---|---:|
| Runs it inside the loop, counts it, goes on (E059) | 27.96 billion |
| Notes it, leaves the loop, runs it after the loop, starts the loop again | 27.91, 28.31 billion |
| Notes it, leaves the loop, and after the loop only leaves the function | 27.90 billion |
| Stores its slot in a global and leaves | 27.52 to 27.65 billion |

A profile of the slow and the fast build has the extra samples in `exec_short` and spread
evenly over its instructions (907 more of 77,000), and the loop's code is the same,
instruction for instruction, in both. It is not anything the loop does: it is the function
having two more calls in it, and what the compiler makes of the function around the loop
for that. Where that goes was not found, and after E056 not looked for further. **As
fixed**: `exec_short` stores the slot of the block it came to in `jit_at` and returns;
`exec_one` then has `jit_blocks` run that block and the ones that follow it, and calls
`exec_short` again.

**What that does to the JIT.** With `--jit` the boot is now 159.9 billion host instructions
and 29.2 billion cycles, 5% over main, where E059 had it 0.7% under. Leaving `exec_short`
and entering it again for each block is a hundred-odd host instructions (the state is
copied to `saved` twice), and this stage's blocks are three or four instructions long.
`jit_blocks` goes from block to block without the run in between, so the cost falls with
the share of instructions that are in blocks; the second stage decides it. Until then
`--jit` is slower than no `--jit`, and that is said here and not hidden in a mean.

By the card: the second branch, then a cause the card had not listed.

**Tests.** `s_jitpage`: a block that jumps back to an address in the page below, where in
RAM, at the number the address makes in the first block's page, there is another block; the
second must not be run. Twenty-six wrong translators now, each caught; the one for this
passed until the jump went to a lower page, because a block in a higher page is refused
anyway for lying beyond where the run may go.

## E061: The JIT, second stage: memory operands, the stack, CALL and RET (2026-11-17)

- **Hypothesis**: `mov r, r/m` is 13.4% of all instructions and a block of E059 ends at the
  first one. With the short path of `seg_read` and `seg_write` generated inline (the
  segment's bound, the page crossing, the TLB's tag, then a load or store in RAM), blocks
  run from jump to jump, and most instructions of the boot are in blocks. Generated code
  still never faults: where an access is not on the short path the block leaves *before*
  that instruction, with the registers and flags as they were then and the count of
  instructions it did execute, and the interpreter takes that instruction (a TLB miss, a
  page fault, a store into a page of code). The block's own registers are four that a C
  function must preserve, so blocks are entered through a few generated instructions that
  save them and load the addresses of RAM, the TLB and `seg_top`. With that: **60% or more
  of the boot's instructions in blocks, and the boot's cycles 20% or more under main's**
  (rustx86's JIT, with 58% of the instructions in generated code, took 28% off its
  interpreter's time).
- **What changed since last time**: E059's blocks touched registers only and ran whole.
  This adds loads and stores (`mov` both ways, the arithmetic and CMP and TEST from memory,
  MOVZX, `mov [m], imm`), PUSH and POP of a register, and CALL and RET as ends of a block; a
  block now returns how many instructions it ran.
- **Next move for each result**:
  - Everything passes with `--jit`, the count is the same, and the boot is 10% or more
    under main → keep; then what the blocks still leave out (the arithmetic *to* memory,
    INC and DEC of memory, shifts, 8-bit operations), by a count of what ends blocks
  - Passes, and under 10% faster → a count first: how long blocks are, how often a block
    leaves early, how often the run is entered between blocks; the design is adjusted from
    that before anything is added
  - A test fails only with `--jit` → halve the set of kinds the translator accepts
- **Cut-off**: This stage ends when the suite passes with `--jit` and the boot is measured,
  or at three wrong instructions that halving cannot find.

### Result

2026-11-17. **It works, and it is not faster yet: with `--jit` every test passes and the
boot stops at the same instruction, 38.6% of its instructions run in blocks, and it takes
4% more cycles than main. The count says why: blocks are three instructions long.**
`tools/difftest.sh` has 106 lines, all ok.

| Linux boot to the shell prompt | Host instructions | Cycles, median of three |
|---|---:|---:|
| main (E057) | 145.6 billion | 27.34 billion |
| This source, without `--jit` | 147.2 billion | 27.50 billion |
| This source, with `--jit` | 164.2 billion | 28.49 billion |

With `--jit`: 24,969 blocks, 9.7 MB of code, 637 million guest instructions in blocks,
456 thousand times a block left before its end.

**What was built.** Blocks are entered through twelve generated instructions that save
x19 to x22 and load them with the addresses of RAM, the TLB and `seg_top` and with what a
physical address in the page is above the instruction pointer. `j_mem` is the short path of
`seg_read` and `seg_write`: the offset against `seg_top`, the page crossing, the TLB's tag
in the half for the current privilege level, the page's place in RAM. An access that is not
on it branches to a way out after the block's body, which stores the registers changed so
far, returns the instruction's own address and the count so far, and goes through a piece
of code, shared by the block's ways out, that writes the flags' record to EFLAGS. New in
blocks: `mov` from and to memory and of an immediate to memory, the arithmetic, CMP and
TEST from memory, MOVZX, PUSH and POP of a register, and CALL and RET as a block's end. A
block returns its count; `jit_blocks` stops the chain where a block left early.

**The count the card asked for.**

| | |
|---|---:|
| Times the run came to a block | 139.6 million |
| Blocks run | 214.7 million |
| Instructions in a block run, on average | 3.0 |
| Blocks run one after another, on average | 1.5 |
| The chain ends because what is next is not a block | 130.9 million (94%) |
| ... because the next address is in another page | 6.8 million |
| ... because the block left before its first instruction, or early | 0.8, 0.5 million |

Each time the run comes to a block it leaves `exec_short`, and comes back: a hundred-odd
host instructions for three guest instructions. What the chain stops at, by the kind of
the instruction there:

| Stops at | Share | |
|---|---:|---|
| a shift by CL | 13.6% | not translated |
| the 8-bit `mov`s, the 8-bit TESTs and their pairs | 20% | not translated |
| ADC and SBB | 6.1% | not translated |
| shifts and rotates by a constant | 6.8% | not translated |
| MOVSW, LODSB, SETCC, an instruction with no executor | 8.6% | not translated |
| `mov r, r/m`, `mov r/m, r`, MOVZX, `mov` between registers, of an immediate, arithmetic from memory | 40% | translated, but the block would be one instruction, because what follows is not |

So the blocks are short for want of instructions, not by design: more than half of what
stops them is a dozen kinds, and most of the rest follows from those.

By the card: the second branch (under 10% faster: count, then adjust). The adjustment is
the next card: the kinds above, in the order of the table.

**Tests.** `s_jitmem`: blocks with loads, stores, arithmetic and CMP from memory, MOVZX,
PUSH, POP, CALL and RET, with two accesses that cross into a page mapped elsewhere, a store
into a page of code, a load from a page made not present half way, and a store to a page
whose place in the read TLB another page has. `s_jitseg`: a load beyond a segment's limit
from a block. `s_jitring`: a block in ring 3 loading from the supervisor's page, which the
supervisor's half of the TLB has. The Linux boot with `--jit` is now in `tools/difftest.sh`,
against the boot without. Twenty-two wrong translators of this stage: twenty caught (six
only after the tests above were extended); two are not wrong. A block that left early going
on to look for the next block finds none there; and a block on a 16-bit stack leaves by the
segment's bound wherever the 16-bit and the 32-bit stack pointer would differ. Both checks
stay.

Two things the tests taught about themselves: a load whose result is overwritten before
anything reads it tests nothing (the first crossing load); and a block whose page is
stored into on every pass is dropped on every pass and never runs (the first version of
the store into code).

## E062: The kinds that stop the chains of blocks (2026-11-17)

- **Hypothesis**: E061's count: a chain of blocks stops because what is next is not a block
  (94%), and what is next is one of a dozen kinds the translator does not know, or an
  instruction it knows followed by one of those. Translating them — the 8-bit `mov`s, tests
  and arithmetic, the shifts by a constant and by CL, the rotates by a constant, the
  arithmetic to memory and INC and DEC of memory, NOT and NEG, ADC and SBB, SETCC — and
  taking any condition from EFLAGS where the flags' record cannot give it (so that no block
  has to end before a conditional jump) makes blocks run from jump to jump: **70% or more
  of the boot's instructions in blocks, five or more instructions to a block run, and the
  boot's cycles 10% or more under main's.**
- **What changed since last time**: E061 translated the 32-bit `mov`s, loads and the stack.
  This is breadth, by the table of what stopped the chains, and one change of design: a
  condition can be worked out from EFLAGS in memory, so every conditional jump can end a
  block.
- **Next move for each result**:
  - 10% or more under main → keep; then the cost of going from block to block (the flags
    written out at every exit, the way in through C), by a count of host instructions per
    block run
  - Coverage up and still not 10% under → that count first; the kinds stay
  - A test fails only with `--jit` → halve the set of kinds
- **Cut-off**: This card ends when the suite passes with `--jit` and the boot is measured.

### Result

2026-11-17. **Kept: with `--jit` the Linux boot takes 19% fewer cycles than main and 15%
fewer host instructions, with 68% of its instructions in blocks.** `tools/difftest.sh` has
108 lines, all ok; the boot with `--jit` stops at the same 1,651,240,001 instructions.

| Linux boot to the shell prompt | Host instructions | Cycles, median of six |
|---|---:|---:|
| main (E057) | 145.6 billion | 27.37 billion |
| This source, without `--jit` | 147.1 billion | 27.66 billion |
| This source, with `--jit` (E061) | 164.2 billion | 28.49 billion (then) |
| This source, with `--jit` | 123.3 billion | 22.10 billion |

With `--jit`: 32,113 blocks, 15.8 MB of code, 1,130 million guest instructions in blocks
(68.4%), 918 thousand times a block left before its end. By the card: the first branch (10%
or more under main); its figures were 70% in blocks and 10% faster, and it got 68% and 19%.
Without `--jit` this build reads 1.1% over main in the one layout measured; E060 had it
within 0.1% over three, and `exec_short` has not changed since. It is to be measured over
layouts before it is believed either way.

**What was added.** The 8-bit `mov`s, TEST and arithmetic (for ADD, SUB and CMP the flags'
record holds the operands shifted to the top byte, so that the 32-bit rules give the 8-bit
flags; for the logic ones, the result sign-extended); shifts by a constant, of a register
or of memory, as two new kinds of record (the result and CF, and OF when the count is one;
AF and otherwise OF are left, so the record before is written out first); shifts of a
register by CL and rotates by a constant, whose flags depend on the count and go straight
to EFLAGS; the arithmetic to memory, INC, DEC, NOT and NEG of memory; ADC and SBB, with the
host's own carry; SETCC; and any condition worked out from EFLAGS where the record cannot
give it, so that every conditional jump can end a block. `--jit-off N` tells the translator
to leave groups of kinds alone, for finding a wrong one.

**Two bugs, and how each was found.** (1) Exits for the new kinds of record branched to
themselves: the code the exits share for writing the flags out was emitted for the first
five kinds of record only. Every test hung; a debugger attached to the hung process showed
`b .`. (2) ADC and SBB to memory stored their result at the wrong place: the address of
the operand is in a register that the flags' code then used as scratch. **Every test
passed, and the Linux boot ran to twenty billion instructions without reaching its
prompt.** Found as the card said, by halving: with the new groups off the boot was right;
five groups on, five off, twice; then one at a time; ADC and SBB, in seven boots. The
suite had no ADC to memory in a block. It has now (`s_jitops`), and a wrong build that
puts the bug back fails it.

**Tests.** `s_jitops`: forty-odd blocks, one for each of the new instructions, EFLAGS and
the results summed against a trace run. Twenty-seven wrong translators, each caught; five
passed at first. Three for want of an operand: a rotate and a shift by CL of small values
leave OF clear whether it is worked out or not, and the first constant counts were odd
where the wrong build differed only for even ones. Two for want of a case: SETCC was only
ever run on flags from EFLAGS, never on the block's own, and no condition taken from
EFLAGS was a negated one. And once more a test that could not test: its cell of memory was
in the page of its code, so every store dropped every block and none ever ran; the JIT's
count of blocks (none) said so.

**What is left, by this count.** 32% of the instructions are still interpreted: the
string instructions, the rotates through carry and by CL, MUL and DIV, the 16-bit forms,
everything the general path executes, and whatever follows them up to the next place a
block begins. A block that leaves early (918 thousand times) is a TLB miss or a page
fault. And between blocks the flags are written out and the registers stored and loaded
again; the card's next step is the count of host instructions for a block run.

## E063: Blocks through the heads of other blocks, and a refused translation tried again (2026-11-17)

`docs/jit.md` now holds the JIT's design, its state and a list of tasks; this is its first.

- **Hypothesis**: A count on main with `--jit`: a chain of blocks stops 80 million times
  because the next instruction is not a block, and for 50 million of those the instruction
  is one the translator knows. Its translation was refused, because the block would have
  been one instruction long, and `dc_hot` then says "never again". Why it was one long, by
  the kind of the instruction after it: in 15 million it was already the first instruction
  of another block (`K_BLOCK`, which the translator does not look inside); in most of the
  rest it is a kind the translator knows now, or knew then and could not see (an entry not
  yet classified, or not in the cache). If a block is translated through the head of
  another, by that head's own kind, and a refusal for a reason that may pass makes the
  address be counted afresh, most of the 50 million go: **blocks run one after another 4 or
  more times in place of 2.5, and the boot's cycles 5% or more under E062's.**
- **What changed since last time**: E062 added kinds. This adds none; it is about which
  addresses get a block.
- **Next move for each result**:
  - 5% or more → keep; task 3 (the unknown kinds) next, then task 4
  - Under 5% with the chain longer → keep, and task 4 (from block to block in generated
    code) moves ahead of task 3: the cost is then between blocks, not at the chain's end
  - The chain no longer → the count misled; count again what the 50 million are
- **Cut-off**: The same day; the suite with `--jit`, the boot's count, the counts again.

### Result

2026-11-17. **Kept: with `--jit` the Linux boot takes 37% fewer cycles than the interpreter
and 35% fewer host instructions; 90% of its instructions run in blocks.** `tools/difftest.sh`
has 111 lines, all ok. The card asked for 5% under E062 and a chain of 4; it got 20% under
E062 and a chain of 3.7, because the count behind the card had found only half of what was
wrong.

| Linux boot to the shell prompt, medians of six | Host instructions | Cycles |
|---|---:|---:|
| main before the JIT (E057) | 145.8 billion | 28.10 billion |
| This source, without `--jit` | 147.4 billion | 28.14 billion |
| `--jit`, E062 | 123.5 billion | 23.2 billion (in these rounds) |
| `--jit`, through the heads of blocks and tried again | 112.9 billion | 22.0 billion |
| `--jit`, and a block survives its entry | 94.9 billion | 17.73 billion |

**Three steps, each from a count.**

1. *As the card said*: the translator takes an instruction that begins another block by its
   own kind, and a refusal for a reason that may pass (the next instruction not in the
   decode cache, or not classified) makes the address be counted afresh. 71.5% of the
   instructions in blocks, from 68.4%; 8.6% fewer host instructions.
2. *The count again*: 48 million chain stops were still at an instruction the translator
   knows and had refused for good, followed by an instruction it also knows. The reason is
   not in the translator. **`dc_hot` belongs to a slot of the decode cache, and the entry in
   a slot changes**: an entry is driven out by another address that wants the slot, or
   emptied by a store, and made again; the new entry found the slot marked "tried, never
   again" by its predecessor. With the count reset when a slot gets a new entry, blocks came
   back at once, and the code filled its 32 MB half way through the boot, every block being
   translated again each time its entry came back; translation stopped, and the share in
   blocks fell to 43%.
3. *So*: a block outlives its entry. The slot remembers the address its block begins at;
   when an entry is classified and the slot's block is that address's and its page has not
   been written, the entry heads the block again (`jit_reclaim`). And when the code is full,
   every page's generation is moved on and translation starts from empty (`jit_flush`):
   the boot does that once. 89.6% in blocks.

Also done, from the list in `docs/jit.md`: `--jit` on a host that is not arm64 says so and
does nothing (`jit_alloc` returns 0 there).

**Tests.** `s_jitslot`: two pieces of code 20000h apart, which want the same slot; the
first has a block, the second takes the slot, the first's entry is made anew and gets its
block back, in the run that classifies it. `--jit-size N` makes the room for code small,
and the suite runs the JIT's self-checks once more with 70,000 bytes, so that the code is
dropped while they run. Five wrong builds: three caught (a block given back to another
address; a flush that drops nothing, by the small-room runs; the run executing the given-back
entry by its kind, which is "a block" and has no executor, by `s_jitslot`). Two are not
wrong: without the step through another block's head there are fewer blocks and the same
answers; and a block given back in spite of its page's generation is dropped where it is
next reached, by the check there.

By the card: the first branch. Task 3 (the unknown kinds) is next, then task 4.

## E064: Where an interactive Linux boot's time goes (2026-11-17)

- **Hypothesis** (the owner's, from watching it): with `--jit` the boot in a terminal still
  feels slow, and drawing looks like what takes the time. Checked before anything is
  changed: the boot through a pseudo-terminal, stopped at the prompt, against the same boot
  headless. If it is drawing, the process's own CPU time is most of the wall time; if it is
  the pacing against real time (`run_serial` sleeps until a second of guest time has taken
  a second), most of the wall time is sleep, and the wall time is the boot's guest time,
  1,651 million instructions at 76.4 million a second: 21.6 seconds, whatever the host does.
- **What changed since last time**: the JIT made the host three times faster than the
  guest's clock; before it, the two were close enough that pacing did not show.
- **Next move for each result**:
  - Mostly sleep → pace only the guest time that passes while the machine is halted, for a
    kernel (Linux waits by halting; a DOS program may wait by counting, and keeps the old
    pacing); `sleep 3` must still take three seconds
  - Mostly CPU, and in the console → look at what is written to the terminal and how often
- **Cut-off**: The same hour.

### Result

2026-11-17. **Sleep: 6.8 seconds of CPU in 22.0 seconds of wall time, and the 22.0 is the
guest's 21.6. Paced only while halted, the boot in a terminal takes 7.5 seconds with
`--jit` and 11.6 without.**

| Linux boot to the prompt, in a pseudo-terminal | Wall time |
|---|---:|
| main, `--jit` | 21.6 s |
| unpaced (now the default for a kernel), `--jit` | 7.5 s |
| unpaced, interpreter | 11.6 s |
| `--paced`, `--jit` | 21.6 s |

`run_until` adds up the guest time it skips while the machine is halted (`idle_insns`);
the two console loops, when `unpaced`, sleep for that and for nothing else, keeping count
of what they have slept so that a sleep that overshoots is made up. A kernel is unpaced
unless `--paced` is given; a disk image is paced unless `--unpaced` is. The guest's clock
runs ahead of the wall while it computes: after the boot its uptime says 21 seconds.

`tools/console_test.py` drives the real thing through a pseudo-terminal and passes: the
boot to the shell in 11.0 seconds (it does not use `--jit`), `sleep 3` in 3.08 seconds of
real time, Ctrl-] leaves; ELKS and FreeDOS as before (`sleep 3` in ELKS 3.25 seconds).
Nothing here touches what a headless or scripted run does, which was never paced.

### Addendum: the clocks should agree (the owner's question)

2026-11-17. "Does the time not disagree with a real machine? It feels too fast." It does
disagree: unpaced, the guest's clock runs ahead of the wall while the guest computes, three
times as fast with `--jit`, and that had been made the default for a kernel. The owner chose
the other way to be faster: **a faster guest CPU under the same clock.** `--speed N` makes
a second of guest time N times as many instructions (`tick_insns` times N); pacing stays as
it was, and is the default again for everything. `--unpaced` stays as an option.

| With `--jit`, in a pseudo-terminal | Instructions to the prompt | Guest time | Real time |
|---|---:|---:|---:|
| `--speed 1` | 1,651 million | 21.6 s | 21.6 s |
| `--speed 2` | 1,767 million | 11.6 s | 11.6 s |
| `--speed 3` | 1,908 million | 8.3 s | 9.2 s |
| `--speed 4` | 2,055 million | 6.7 s | 9.8 s |
| `--speed 6` | 2,355 million | 5.1 s | 11.1 s |
| `--speed 8` | 2,658 million | 4.4 s | 13.3 s |
| `--unpaced` at speed 1 | 1,651 million | 21.6 s | 7.5 s |

Two things the table says. A faster guest does more work to boot: each step of speed adds
about 130 million instructions, the kernel's own delay loops, which are calibrated to last
a time and so spin more on a faster CPU. And the host delivers about 200 million guest
instructions a second over this boot (much of it code run for the first time, which the JIT
has yet to translate), so up to speed 2 the clocks agree exactly, at 3 the wall is a second
behind the guest by the prompt, and from 4 on the guest's clock falls behind the wall and
the boot gets longer. 3 is the fastest boot with the clocks near each other on this
machine: 9.2 seconds against the default's 21.6.

Checked through a pseudo-terminal, with a shell command typed at the prompt: `sleep 3`
takes 3.01 seconds of real time at speed 3, 3.03 at speed 2 and 3.07 unpaced. And the
clocks, by `/proc/uptime` at the prompt (the kernel starts counting about three guest
seconds after it is entered): at speed 3 the guest says 5 seconds where 10.8 of real time
had passed in that run, at speed 2 it says 7 for 13.3; unpaced it says 13 for 7.6, which is
the disagreement the owner saw. (Those real times are of runs driven by a script that reads
the terminal; the table's are the emulator's own.)

## E065: From block to block inside generated code (2026-11-17)

Task 4 of `docs/jit.md`.

- **Hypothesis**: After E063, 245 million blocks are run in a boot and each is a round trip:
  out of the block (the registers stored, the flags written, a return through C), a turn of
  `jit_blocks` (the page's generation, the time, the limit, a look in the decode cache), and
  in again (through C, the registers loaded). A guest instruction costs 57 host instructions
  with the bodies a fraction of that. If a block's way out to a known address in the same
  page is a branch that `jit_blocks` fills in the first time it sees where it leads, the
  next block is entered with the guest's registers still in host registers, and all that is
  left between two blocks is a count-down of the time and the flags' record written out:
  **the boot's host instructions under 75 billion (from 95) and its cycles 15% or more
  under E063's.**
- **What changed since last time**: nothing in what is translated. The way in now loads
  the guest's registers and the way out stores all of them, once for a whole chain; a block
  begins by taking its length off the time left (x23) and leaves if that is not enough; and
  a block's exits to fixed addresses are link slots.
  - *Why a link needs no check of the page's generation*: links are only made inside a
    page. If the page is written, every block in it is stale together, and a stale block is
    only ever entered from Goose, which checks, or from another block of the same page,
    which is stale too and so is never entered.
  - *Why it needs no check of the code segment's limit*: where the limit cuts into the page
    (the run's last address is not the page's), the chain is given time for one block only.
- **Next move for each result**:
  - 15% or more → keep; task 5 (the flags' record across a block's end) is then the largest
    thing left between blocks
  - Under 15% → count host instructions per block run again before task 5
  - A test fails only with `--jit` → `--jit-off 1024` (no linking) tells the linking from
    the new way in and out
- **Cut-off**: The suite with `--jit`, the boot's count, the stops; wrong builds for the
  count of time and the link.

### Result

2026-11-17. **Kept: with `--jit` the Linux boot takes 74.6 billion host instructions and
15.2 billion cycles: 16% fewer cycles than E063, 47% fewer than the interpreter.**
`tools/difftest.sh` has 113 lines, all ok; the boot stops at the same instruction.

| Linux boot to the shell prompt, medians of six | Host instructions | Cycles |
|---|---:|---:|
| Interpreter (main before the JIT) | 145.6 billion | 28.63 billion |
| This source, without `--jit` | 147.2 billion | 28.84 billion |
| `--jit`, E063 | 94.9 billion | 18.16 billion |
| `--jit`, linked | 74.6 billion | 15.20 billion |

Generated code is entered 64.3 million times in a boot, where 245.7 million blocks were run
one call each; 24,358 link slots are filled in. By the card: the first branch.

**As built.** The way in saves x19 to x25, loads the guest's eight registers and the half
of the TLB, and jumps to a block. A block begins `subs x23, x23, #n; b.lt`: its length off
the time, or out. Each exit to a fixed address writes the flags' record out and ends in one
branch, the link slot, which goes to three instructions behind the body that leave with the
address in w16 and the slot's own address in x17. A way out before an instruction gives
back the time for the instructions not executed and leaves with x17 zero. The way out
stores the eight registers and returns the address, the count (what x23 was on the way in,
less what it is) and the slot. `jit_blocks` looks the address up; if it begins a good block
in the page, it writes a branch to that block into the slot.

**Tests, and what the wrong builds showed about them.** Nine wrong builds; eight caught,
three only after the tests changed:

- *The stops did not test the JIT at all.* `s_pairs`, stopped after 1,200 to 1,600
  instructions, has made no block by then (a block is made at the eighth arrival); the
  sweep passed whatever the count of time did. It is now taken in `s_jitchain`, a loop whose
  body is a chain of blocks, CALL and RET among them, late in its 400 turns: a build that
  does not give a block's length back when there is no time for it fails 185 of the 400.
- *A RET that leaves through a link slot* (x17 not cleared) has Goose write a branch at
  whatever was in x17. Only the Linux boot caught it; now `s_jitchain` does, and `s_jitmem`
  has a block where its RET comes back.
- *A chain where the code segment's limit cuts into the page.* `s_cslimit` had one block.
  It now has two short blocks and then a row of INCs that begins where a run may still go
  and ends far beyond the limit; with a chain allowed there, the row runs to its end.

The ninth, a link made to a block of an older generation, is not reachable: such a block
is dropped the first time the interpreter comes to it, which is before anything can be
linked to it. The check stays.

**Found on the way: a loop with no instruction for the general path in it never gets a
block.** Arrivals are counted where a run of the interpreter begins and where a block
ends. A loop made only of instructions with short executors is one run, for as long as the
time lasts, and is never counted; `s_jitchain` has a CLD in its loop for that reason. The
Linux boot does not show it, because the timer ends a run a thousand times a second. It is
on the list in `docs/jit.md`.

## E066: The kinds the JIT still left to the interpreter (2026-11-17)

Task 3 of `docs/jit.md`.

- **Hypothesis**: E063's count: of the times a chain of blocks stopped, 31 million were at a
  kind with an executor that the translator does not know: `mov` with a 16-bit operand 7.0
  million, IMUL 6.8, MOVSW 6.7, LODSB 2.4, and RDTSC behind another 6.5 million. With E065
  generated code is entered 64 million times in a boot, so these are now a larger share of
  what sends it back. Translated (`mov` of 16 bits both ways, IMUL r, r/m, the seven string
  instructions without REP, RDTSC): **generated code entered under 45 million times, 93% or
  more of the instructions in blocks, and the boot's cycles 5% or more under E065's.**
- **What changed since last time**: E065 changed how blocks follow one another; this is
  breadth again, on that. The string instructions are the first with two accesses to memory
  (both are tried before anything is stored), and RDTSC the first that needs the virtual
  time, which generated code has as what it was on the way in plus what has run since.
- **Next move for each result**:
  - 5% or more → keep; then count what is left between blocks for task 5 (the flags)
  - Under 5% → keep if the count of entries fell as said; the time is then elsewhere, and
    the count for task 5 says where
  - A test fails only with `--jit` → `--jit-off` with the new groups' bits, one at a time
- **Cut-off**: The suite with `--jit`, the boot's count, wrong builds for each new kind.

### Result

2026-11-17. **Kept: with `--jit` the Linux boot takes 58.0 billion host instructions and
12.95 billion cycles: 13% fewer cycles than E065, 55% fewer than the interpreter. 95.4% of
its instructions run in blocks.** `tools/difftest.sh` has 117 lines, all ok.

| Linux boot to the shell prompt, medians of six | Host instructions | Cycles |
|---|---:|---:|
| Interpreter (main before the JIT) | 145.7 billion | 28.97 billion |
| This source, without `--jit` | 147.4 billion | 28.75 billion |
| `--jit`, E065 | 74.7 billion | 14.96 billion |
| `--jit`, with the new kinds | 58.0 billion | 12.95 billion |

Generated code is entered 34.5 million times (64.3 before; the card said under 45), 1,576
million instructions are in blocks (the card said 93%; 95.4%). By the card: the first
branch.

**What was added.** `mov` with a 16-bit operand, both ways and both opcodes (the low half
of a register is inserted; the high half stays). IMUL `r, r/m`: the product in 64 bits,
CF and OF where it does not fit 32, the other flags left. The seven string instructions
without REP as one function: a read at ESI and a write at EDI, each by the short path and
both before anything is stored; SCASB leaves an 8-bit SUB's record; ESI and EDI step by the
operand's size, down when DF is set in EFLAGS. RDTSC: the virtual time on the way in (x25),
plus the time taken off since (x24 less x23), less what of the block is still to come,
which is filled in when the block's length is known.

**One bug**: IMUL multiplied by the wrong register. The opcode's constant, copied from an
assembled example, had the example's second register still in it. test386 failed and the
Linux boot did not reach its prompt; `--jit-off` with the four new groups' bits found the
group in five boots.

**Tests.** `s_jitstr`: the string instructions forwards and backwards, 16-bit moves by both
opcodes, IMUL from a register and from memory, summed against a trace run. `s_jittsc`: two
RDTSCs five instructions apart in one block and a third in the next, sixteen times: 240.
Fourteen wrong builds, each caught; four passed at first. A SCASB with its result worked
out the wrong way round changes only the flags that are written to EFLAGS, which nothing
read; a 16-bit move between registers that moves 32 bits shows only if the upper halves
differ, and, for the opcode an assembler does not use, only if the test has that opcode.
The test script ran the JIT's self-checks with little room for code on the default
machine, where RDTSC is no instruction; it now picks the machine for that one.

## E067: What generated code comes back for (2026-11-18)

The count `docs/jit.md` left open after E066, before choosing among tasks 4b, 5, 11 and 12.

- **Hypothesis**: Generated code is entered 34.5 million times in a boot. If the trips are
  what the time is, a profile shows the interpreter's functions with a share far above the
  4.6% of the instructions they execute, and the count says which trips there are most of.
- **What changed since last time**: E063's count was of chain stops in Goose; since E065 a
  block is left through a link slot, a way out, a RET or for want of time, and the count
  tells them apart (the way out's second value: 0, 1 short, 2 RET, a slot's address).
- **Next move for each result**:
  - Trips cost a third of the time or more → the tasks that remove trips first (4b, RET,
    the kinds blocks stop at), the flags (5) after
  - Generated code itself is nine tenths of the time → task 5 first
- **Cut-off**: One counting build (`build/jitcount2.py`), one `sample` of a boot.

### Result

2026-11-18. **The trips are half the time.** A sample of the boot (3,302 samples): generated
code about 52%; `exec_short` 21.5%, `exec_general` 8.6%, `exec_one` with `jit_blocks` in it
8.5%, the rest of Goose about 9%. The interpreter executes 4.6% of the instructions; what
it costs is the start of a run after each trip. By the card: the first branch.

| Generated code came back, millions | All | To another page | To an address with no entry | To an entry that heads no block | To a block |
|---|---:|---:|---:|---:|---:|
| Through a link slot | 23.76 | 8.93 | 0.63 | 14.18 | 0.03 |
| At a RET | 8.21 | 7.12 | 0.01 | 0.19 | 0.88 |
| At a way out (a memory operand off the short path) | 2.43 | 0.00 | 0.02 | 0.15 | 2.26 |
| For want of time | 0.09 | | | | 0.09 |

Of the 14.18 million slots that led to an entry heading no block: 8.27 million were at an
instruction with no executor, 3.49 million at a lone CALL and 0.96 at a lone JMP (a block of
one instruction is not made, E059), the rest at a plain instruction followed by one of
those. The instructions with no executor, by opcode, in millions: `mov eax, moffs` 1.31,
group 83 with a prefix 0.74, MUL 0.34 and DIV 0.18, REPE CMPSB 0.52, `push r/m` 0.35, LEAVE
0.41, PUSHF 0.36, CMPXCHG 0.35, `push imm8` 0.23, BSWAP 0.21, SHRD 0.33, REP MOVSD 0.20,
`mov moffs, eax` 0.17, and a tail of thirty more below 0.2 each. 4.88 million entries
executed nothing: a way out taken at an instruction that heads a block enters that block,
which leaves at once.

## E068: A block of one instruction, where that is a jump (2026-11-18)

- **Hypothesis**: E067: 4.5 million link slots lead to a lone CALL or JMP, which heads no
  block because a block of one instruction was not worth a trip from Goose (E059). Reached
  through a link it costs no trip. Made a block when the one instruction is a JMP, a
  conditional jump, a CALL or a RET: **generated code entered 3 million times fewer.**
- **What changed since last time**: E059's rule was made when every block was entered from
  Goose. Since E065 a block's cost of entry through a link is two instructions.
- **Next move for each result**:
  - 3 million fewer → keep, on to E069
  - Fewer than 1 million fewer → the lone jumps are reached some other way; count again
- **Cut-off**: The suite, the boot's count.

## E069: Out of the page inside generated code (2026-11-18)

Task 4b of `docs/jit.md`, and the RET with it.

- **Hypothesis**: E067: 8.93 million link slots and 7.12 million RETs lead to another page,
  and 0.88 million RETs to a block in the same page. A run of the interpreter changes page
  when the TLB has the new page for reading at this privilege level (E042); generated code
  can make the same test. One piece of code after the way in ("the far way"), given an
  instruction pointer: the page's linear address, the page whole inside the code segment's
  limit, the TLB's tag, the address in RAM, the slot's `jit_head` and `jit_gen` against the
  page's `code_gen`, then w22 for the new page and a branch to the block. Anything else
  goes to the way out as now. A RET and a link slot to another page go there. No slot is
  patched to another page, so nothing depends on a second page staying as it was: the far
  way looks every time. **Generated code entered 12 million times fewer, and the boot's
  cycles 10% or more under E066's.**
- **What changed since last time**: E065 linked inside a page because a store into a page
  makes all its blocks stale together. The far way does not link; it checks the generation
  where Goose does, at every arrival. The way out returns the instruction pointer, since
  w22 may no longer be the run's.
- **Next move for each result**:
  - 10% or more → keep; then the instructions with no executor (task 12), by E067's list
  - Entries fall as said and the cycles less than 5% → keep; the trips were not the time,
    sample again
  - A test fails with `--jit` only → a new bit of `--jit-off` turns the far way off; halve
- **Cut-off**: The suite with `--jit`, the boot's count and time, wrong builds for each test
  the far way makes (limit, TLB tag, head, generation).

### Result (E068 and E069, measured together)

2026-11-18. **Kept: generated code is entered 16.5 million times in a boot (34.5 before),
25.2 million arrivals are taken by the far way, and the boot takes 48.6 billion host
instructions (58.1) and 5 to 8% fewer cycles.** `tools/difftest.sh` has 119 lines, all ok.

| Linux boot to the shell prompt | Host instructions | Cycles, median of 4 | Cycles, least of 5 (a busier hour) |
|---|---:|---:|---:|
| `--jit`, E066 | 58.1 billion | 13.3 billion | 13.08 billion |
| `--jit`, E068 and E069 | 48.6 billion | 12.17 billion | 12.42 billion |

By E069's card: the entries fell as said (18 million fewer; the card said 12 with E068's 3),
the cycles by less than the 10% it said: its second branch is the nearest, and a second
sample was taken. Generated code is now about 63% of the samples (52), `exec_short` 11%
(21.5), `exec_general` 9%, `exec_one` 7%. What is left of the trips, in millions: a link
slot to an instruction with no executor 6.95, a way out 2.5, the far way finding nothing
1.96, a slot to an address with no entry 0.46. E068 by itself cannot be told from the count:
with the far way off (`--jit-off 32768`) there are 41.7 million entries, more than before,
because the lone jumps are blocks now and each leaves for another page.

**What was built.** The far way is fifty instructions after the way out, with the addresses
of `jit_head`, `jit_gen`, `code_gen`, `jit_code` and two words of the Goose program's
(`jit_ctx`) beside it. A block that ends at a RET or at a fixed address in another page
branches to it. The way out now returns the instruction pointer (w16 less w22), because w22
may be another page's than the run's; `jit_blocks` adds the run's own. Two more things
found by the count: a link slot of a block in a page the far way went to is linked from
Goose by looking the address up in the TLB (the run is still on its first page then), and a
way out taken before an instruction that heads a block no longer enters that block to have
it leave at once (4.9 million entries that executed nothing): `jit_blocks` says so and
`exec_one` goes to the general path. The room for code is 64 MB: the boot's 65.7 thousand
blocks take 31.8 MB.

**Tests.** `s_jitfar`: a loop calls a function in another page, forty passes four times:
as it is; after a store into the function through another address; after the page is
mapped elsewhere and the TLB's place for it is taken by another page that maps to the old
code; and from a code segment whose limit is inside the function, where the RET faults.
Five wrong builds (each of the four tests of the far way made to pass always, and w22 not
changed), each caught by it. The first four wrong builds were themselves wrong (a NOP where
the branch was is later patched as a branch: an illegal instruction), which a return code
showed; and the tag's test was not reached until the CALL was put in a block of its own,
because a block that reads memory left by its way out first and the interpreter made the
call.

## E070: The flags' record kept from block to block (2026-11-18)

Task 5 of `docs/jit.md`.

- **Hypothesis**: Every block writes EFLAGS out from the record where it ends: about thirty
  host instructions, and the same again in each of its ways out's shared tails, which is
  most of a block's 480 bytes. The block that follows nearly always sets the flags anew
  before anything reads them. Kept instead: the record stays in w1 to w3 and its kind goes
  into w26 where a block ends (one instruction); a block begins not knowing the kind, and
  where it needs EFLAGS itself (INC, a shift, ADC, a condition on flags it did not set) it
  calls code after the far way that writes them out by the kind in w26. The way out does
  the same before it returns. **The boot's host instructions 15% or more under E069's,
  cycles 8% or more, and the code under 20 MB.**
- **What changed since last time**: E061 chose to write the flags at each end because each
  block was entered from Goose, which wants EFLAGS right. Since E065 and E069 most blocks
  are entered from generated code.
- **Next move for each result**:
  - Both as said → keep; task 12 next
  - Instructions fall and cycles do not → keep for the size; sample for what the cycles are
  - A test fails with `--jit` only → the kinds one at a time with `--jit-off`; a stop sweep
    (`tools/jit-firstbad.sh`) on the self-check that fails
- **Cut-off**: The suite with `--jit`, the boot's count and time, a self-check in which a
  record of each kind crosses a block's end and is read on the other side, and wrong builds
  for it.

### Result

2026-11-18. **Kept: the boot takes 46.4 billion host instructions (48.7) and about 9% fewer
cycles; the code is 25.1 MB (31.8).** `tools/difftest.sh` has 121 lines, all ok.

| Linux boot to the shell prompt, five rounds | Host instructions | Cycles, median | Cycles, least |
|---|---:|---:|---:|
| `--jit`, E066 | 58.1 billion | 14.48 billion | 13.76 billion |
| `--jit`, E069 | 48.7 billion | 13.60 billion | 12.41 billion |
| `--jit`, the record kept | 46.4 billion | 12.42 billion | 11.49 billion |

(The machine was busy for these rounds: three wrong builds from earlier in the day had hung
and were still running, found by `ps` and stopped before this table; a system update ran
during it. The instruction counts do not depend on that.)

By the card: the instructions fell by 5%, not 15%; the cycles by 8% or more; the code is
not under 20 MB. The second branch, so a count (`build/jitcount3.py`): 250.8 million blocks
are begun in a boot, 6.4 instructions each. EFLAGS is still written out 150 million times
inside blocks: 90 million times from a record the translator knows (rotates 25.1 million,
shifts by CL 16.8, ADC and SBB 22.7, shifts by a constant 16.3, IMUL 6.0, INC and DEC 2.9)
and 61 million times a block asks without knowing (shifts by CL 16.1, by a constant 9.7,
INC and DEC 29.4, a conditional jump at the head of a block 3.3), of which the flags' code
finds a record waiting 44 million times. Those are instructions that keep some of the old
flags or read one: what E071 is about.

**What was built.** w26 holds the kind of the record in w1 to w3 where a block ends, 0 for
none; x27 is scratch for the far way, which no longer uses w1 to w3. The translator begins
a block with the kind `F_ANY`: where EFLAGS is needed before the block has set the flags
itself, it emits `cbz w26` over a call to *the flags' code*, which is after the far way: a
jump by a table on w26 to one copy of what `jit_flags` generates for each kind. The way out
calls it too. A block's ways out lost their shared tails: each puts the kind it knows in
w26 and goes to the way out.

**Tests.** `s_jitflags`: an instruction of each kind of record, a JMP that ends the block,
and in the next block nothing, or an instruction that reads the carry (ADC, SBB), keeps it
(INC, DEC), keeps all but two (ROL, ROR), keeps the overflow (SHL), tests a flag (SETcc, a
conditional jump); a RET between; a record made and written out in the second block; a
way out in the second block. EFLAGS after each, summed against a trace run. Seven wrong
builds, each caught by it; three passed at first. A stale kind left in w26 by a block that
has written its own record out shows only if that block made a record after the one it
inherited; a way out that does not pass its kind shows only if the access really leaves
(`mov eax, [addr]` is an instruction with no executor: the block ended before it); and the
flags' code set w26 to 0 for nothing, since the block that called it says so itself where
it ends: taken out.

## E071: Flags that nothing reads are not made (2026-11-18)

- **Hypothesis**: E070's count: EFLAGS is written out 150 million times inside blocks, each
  about thirty host instructions, for instructions that keep some of the old flags (shifts,
  rotates, INC, DEC, IMUL) or read the carry (ADC, SBB). Three things, none of which changes
  what the guest can see:
  1. Where the instructions that follow in the block set all six flags before any reads
     one, with no way out and no end of the block between, the flags of this instruction
     are never seen: neither the old ones are written out nor its own made.
  2. INC and DEC keep only the carry: of a record the block made, only the carry is put
     into EFLAGS (six instructions).
  3. ADC and SBB read only the carry and set all six: the carry is taken from the record,
     and nothing is written out first.
  **EFLAGS written out inside blocks under 60 million times, and the boot's host
  instructions 5% or more under E070's.**
- **What changed since last time**: E070 moved the writing from every block's end to where
  it is needed; this is about the places that still need it.
- **Next move for each result**:
  - 5% or more → keep, then E072
  - Under 2% → the look ahead finds few; count how far the next setter is and what is
    between, before anything else
  - A test fails with `--jit` only → `--jit-off 65536` turns the look ahead off; halve
- **Cut-off**: The suite, the boot's count and time, cases in `s_jitflags` for each of the
  three with the flags read afterwards and not, wrong builds.

## E072: The page's end and the TLB's tag in one comparison (2026-11-18)

- **Hypothesis**: A memory access of two or four bytes costs seventeen host instructions
  before the load or store, three of them the test that it does not cross a page. The
  TLB's tag at a page's index can only be that page's number or one with the same low
  eight bits; the page of the access's last byte, where it crosses, is the next one. So
  comparing the tag with the page of the *last* byte makes both tests at once: one `add`
  for three instructions. **The boot's host instructions 2% or more under E071's.**
- **What changed since last time**: Nothing in the design; it is the inline short path of
  E061, two instructions shorter.
- **Next move for each result**:
  - 2% → keep
  - Less → keep if the suite passes (it is not slower); memory accesses are then fewer
    than thought
- **Cut-off**: The suite (`s_pagecross`, `s_jitmem`), the boot's count, one wrong build.

### Result (E071)

2026-11-18. **Kept: the boot takes 42.7 billion host instructions (45.9, 7% fewer) and
10.06 billion cycles (10.86).** By the card: the first branch.

EFLAGS written out inside blocks, millions in a boot (`build/jitcount3.py`):

| | E070 | E071 |
|---|---:|---:|
| Inline, from a record the block made | 89.9 | 20.7 |
| Asked by a block that inherited whatever there was | 61.1 | 42.8 |
| The flags' code found a record and wrote it (the way out's 16.5 included) | 60.5 | 43.2 |

What is left inline: rotates 9.5 million and shifts 9.5 whose flags something may see (a
memory operand follows, or the block ends). What is left asked: INC and DEC 29 million,
which keep the carry of a record the block did not make and have the whole of it written.

**What was built.** `j_dead` looks ahead from an instruction through the decode cache, as
far as twelve instructions: true if one that sets all six flags and reads none comes
before any that reads a flag, has a memory operand (a way out, after which the interpreter
or a fault's handler would see EFLAGS), or ends the block. Between, instructions that touch
no flag, and those that keep some without reading any (INC, DEC, shifts, rotates, IMUL,
between registers), which by the same look ahead make none themselves. Where it is true,
a shift, a rotate, INC, DEC, IMUL, ADC or SBB is the bare host instruction. Where it is
not: INC and DEC put only the carry of the block's own record into EFLAGS; ADC and SBB
take the carry from the record and write nothing out first. `--jit-off 65536` turns the
look ahead off.

**Two orders that mattered**, both found by reading before running: the flags' code and
the inline writing use w6, where the place of a memory operand waits for the store, so
whatever is written out is written before the place is worked out; and the way out of a
memory operand has to leave with the record as it was, so for INC and DEC of memory the
carry is settled after the operand's way out, not before.

**Tests.** `s_jitdead`: nineteen blocks (the carry kept, the carry read, flags never
seen, flags seen after an instruction that touches none and after one with no executor),
and four in which the instruction after a shift, a rotate, an INC or an ADC faults on a
segment's limit and the handler sums the EFLAGS in its frame. Sixteen wrong builds, each
caught by it; five passed at first. ADC after a logical instruction and a shift by CL
with the wrong count register were not in the test or had the same value in both
registers; the end of the block taken for a setter needed an instruction with no executor
that has a ModRM byte, since the look ahead refuses the others earlier. Two wrong builds
were no wrong builds and were dropped: an INC between taken as touching no flag (it finds
its own flags never seen: this became the rule above and found more), and the carry of an
INC's record computed again (it is in EFLAGS already). Not covered by a wrong build: the
guards that keep a block from being cut between the instruction and the setter (its
length, the room for ways out). A block cut there would only show stale flags to an
interrupt taken between the two blocks.

### Result (E072)

2026-11-18. **Kept: 41.1 billion host instructions (42.7, 3.8% fewer), 9.72 billion cycles
(10.06).** By the card: the first branch. One wrong build (the tag compared with the page
of the first byte), caught by `s_jitmem`. `tools/difftest.sh` has 123 lines, all ok.

| Linux boot to the shell prompt, medians of five, one hour | Host instructions | Cycles |
|---|---:|---:|
| Interpreter (main before the JIT) | 145.7 billion | 28.36 billion |
| `--jit`, E066 (this morning's main) | 58.0 billion | 13.35 billion |
| `--jit`, E070 | 45.9 billion | 10.86 billion |
| `--jit`, E071 | 42.7 billion | 10.06 billion |
| `--jit`, E072 | 41.1 billion | 9.72 billion |

With `--jit` the boot now takes 66% fewer cycles than the interpreter, and 27% fewer than
this morning.

## E073: Kinds that only the translator knows (2026-11-18)

Task 12 of `docs/jit.md`, the first part.

- **Hypothesis**: E069's count: 6.95 of the 16.5 million trips back to Goose are at an
  instruction with no executor. The translator reads what `classify` left in an entry, so
  such an instruction needs a kind; a kind above `K_LAST` that `exec_short` leaves to the
  general path as it does `K_NONE` costs the interpreter nothing. Given kinds, and
  translated: `mov eax, moffs` and back, LEAVE, `push imm`, `push r/m`, XCHG between
  registers, BSWAP, CDQ, CLD and STD, a rotate by one, MOVSX, and group F7's MUL, IMUL, DIV
  and IDIV (a division that would fault takes a way out). **Generated code entered under
  13.5 million times, and the boot's host instructions 3% or more under E072's.**
- **What changed since last time**: E066 translated kinds that had executors. These have
  none; `classify` gives them kinds only when the JIT is on.
- **Next move for each result**:
  - Both as said → keep; count again for what is left (REP strings, CMPXCHG, SHRD, PUSHF,
    group 83 with a prefix)
  - Entries fall and instructions do not → keep; the trips for these were cheap ones
  - Without `--jit` slower by 1% or more (the one comparison changed in `exec_short`) →
    pad the layout as E060 did, before anything else
- **Cut-off**: The suite with `--jit`, a self-check with every new kind summed against a
  trace run, wrong builds, the boot's count and time with and without `--jit`.

### Result

2026-11-18. **Kept: generated code is entered 11.3 million times in a boot (16.5), and the
boot takes 35.9 billion host instructions (41.1, 13% fewer) and 8.40 billion cycles (9.32,
10% fewer).** By the card: the first branch. `tools/difftest.sh` has 125 lines, all ok.

| Linux boot to the shell prompt, medians of five, one hour | Host instructions | Cycles |
|---|---:|---:|
| Interpreter (main before the JIT) | 145.6 billion | 27.59 billion |
| This source without `--jit` | 147.2 billion | 27.75 billion |
| `--jit`, E072 | 41.1 billion | 9.32 billion |
| `--jit`, with the new kinds | 35.9 billion | 8.40 billion |

With `--jit` the boot takes 70% fewer cycles than the interpreter. 98.2% of the guest's
instructions run in blocks (1,621 of 1,651 million); the far way finds a block 25.7 million
times. Without `--jit` the source is where it was (0.6% in the cycles, inside what the
rounds differ by; the 1.1% in instructions is the JIT's hooks, there since E062).

**What was built.** Fourteen kinds from 96 to 109 (`K_J_...`, `K_JLAST`), which `classify`
gives only when the JIT is on. Three places had to know that a kind may now be neither an
executor's nor `K_NONE` nor a block: `exec_short` after it classifies (one comparison,
against `K_LAST` where it was against `K_BLOCK`), `exec_general` where it runs a cached
instruction by its executor (now only if it has one; otherwise it decodes it like any
other, with the operand from the cache), and the translator's own tests (`K_JLAST`).
DIV and IDIV work out the quotient in 64 bits and take the way out, before anything is
changed, on a divisor of zero or a quotient that does not fit; MUL and IMUL make their two
flags only where something may see them (`j_dead`). `--jit-off 131072` turns the new kinds
off.

**Tests.** `s_jitkinds`: every new kind, with EAX, EBX, EDX and EFLAGS after each summed
against a trace run; a division by zero and two whose quotients do not fit, whose handler
sums the registers it finds. Twenty-four wrong builds, each caught; nine passed at first.
The pushes were followed by `add esp, 8`, so nothing read what they pushed; `movsx ebx, al`
is the same whichever way AL is fetched (AH is not); the divisions meant to overflow came
after the one by zero and so divided by zero as well; `push ebx` the long way pushed a
register that held the same value as the one the wrong build pushed; and two wrong builds
were wrong themselves (register 31 is the stack pointer in a comparison with a constant).
Since CLD is now translated, the earlier self-checks' blocks no longer begin after it: the
wrong builds of E069 to E072 were run again, and one case of `s_jitdead` (flags seen after
an instruction with no executor) needed another such instruction, XCHG having got a kind.

## E074: A clock (M6, first half) (2026-11-18)

The first stage of `docs/roadmap.md` after M5.

- **Hypothesis**: Linux reads the time of day once, from the CMOS clock at ports 70h and
  71h, where g86m answers FFh. With an MC146818 as rustx86 has it (`cmos.rs`: the status
  registers, the time made from a start time and the guest's own time, in BCD), **`date` in
  the guest shows the start time plus what the guest has run: the host's date in the
  console, and a fixed one (2026-01-01, rustx86's) in a scripted or headless run, which
  the tests compare and which has to be the same every time.**
- **What changed since last time**: Nothing was there. The clock runs on guest time
  (instructions, as the timer does), not on the host's: a second of it is a second of the
  PIT's.
- **Next move for each result**:
  - `date` right both ways, the suite passes → keep; the boot's instruction count is a new
    one (the kernel now finds a clock), recorded here; then the disk
  - The kernel waits on the clock (the update-in-progress bit, an interrupt it wants) →
    read what it does in `drivers/rtc/rtc-mc146818-lib.c` and give it that, no more
  - ELKS or FreeDOS sessions change → compare with rustx86, which has the same chip there
- **Cut-off**: `date` in a scripted run against the fixed start; one run in a terminal by
  hand for the host's; the suite.

### Result

2026-11-18. **Kept: `date` in the guest shows the clock's start plus the guest's own
time.** `tools/difftest.sh` has 127 lines, all ok.

- A scripted boot: `Thu Jan  1 00:00:19 UTC 2026` at the first prompt (the boot is 19
  seconds of guest time), and the kernel says `rtc_cmos rtc_cmos: registered as rtc0` and
  `setting system clock to 2026-01-01T00:00:11 UTC`.
- `--rtc host` in a scripted boot, and no option in a pseudo-terminal: the host's date.
  Under `--unpaced` the guest was 17 seconds ahead of the host at the prompt, which is
  what `--unpaced` is: the guest's time runs ahead of the wall while it computes.
- Set from the guest: `date -s '2031-02-28 23:59:50'; hwclock -w; sleep 15; hwclock` gives
  `Sat Mar  1 00:00:05 2031`. `--rtc 951868790` (ten seconds before the end of a leap day
  in 2000) reads `Wed Mar  1` after the boot.
- **The Linux boot's count is a new one: 1,492,760,001 instructions to the first prompt**
  (1,651,240,001 without a clock), the same with `--jit` and without. Timings from before
  this card are not to be compared with timings after it.
- ELKS and FreeDOS sessions pass as they were. The BIOS's time and date services (INT 1Ah,
  AH 02h and 04h), which answered a constant, read the same clock.

**What was built.** In `dev.goose`: 128 bytes of CMOS memory, an index, and the start
time; the clock's registers are made when read, from the start time plus the instruction
count over what a second of the timer is, by the days-to-date arithmetic rustx86 uses.
A write to a clock register moves the start time so that the field reads back as written.
No alarm, no interrupt, no update-in-progress bit; Linux 6.18 asks for none of them to
boot and to run `hwclock`. `--rtc host` or `--rtc SECONDS` sets the start; without it, the
host's time where a terminal is attached and 2026-01-01 elsewhere.

**Tests.** `s_cmos`: the status registers, the start date in BCD and in binary, a date set
just before a leap day ends and read back, and the roll into March after a second of the
guest's time. The Linux session in `tools/difftest.sh` reads the date and sets the clock.
No wrong builds were made for this one.

## E075: A disk (M6, second half) (2026-11-18)

- **Hypothesis**: An ATA disk on the primary IDE channel (ports 1F0h to 1F7h and 3F6h, IRQ
  14), PIO only, backed by an image file that is read and written in place, is enough for
  Linux's `pata_legacy` to find a disk and for a file system on it to be mounted and
  written: **`mount /dev/sda /mnt`, a file written, the guest shut down, and the file is
  there in the next run and in the image as the host sees it.**
- **What changed since last time**: The roadmap named rustx86's `ide.rs` as the oracle. It
  is an ATAPI CD-ROM on the secondary channel, not a disk (rustx86's Linux disk is
  virtio-blk on PCI, which g86m has not). What carries over is the register conventions
  (the signature after a reset, an absent slave reading as zero, the interrupt lowered by
  reading the status). The disk's commands are from the ATA standard, and the test is
  Linux's own driver. The kernel has the driver only as modules (`libata`, `pata_legacy`,
  `scsi_mod`, `sd_mod`, a file system), which go into the initramfs from the same Alpine
  module image rustx86 takes its from, so that they match the kernel.
- **Next move for each result**:
  - Mounted, written, persistent → keep; M6 is done
  - `pata_legacy` does not probe the ports without PCI → its parameters (`probe_all`,
    `all`), read from its source, before any other driver
  - The driver finds the disk and a command is refused → the command and what the standard
    says it returns, one at a time, from the kernel's log
- **Cut-off**: A self-check on the bare ports (IDENTIFY, a sector written and read back);
  a scripted Linux session that mounts, writes, powers off, and a second that reads; the
  image checked from the host.

### Result

2026-11-18. **Kept: Linux finds the disk, takes the ext2 file system on it as its root,
writes it, and what it wrote is there in the next run and in the image file. M6 is done.**
`tools/difftest.sh` has 130 lines, all ok.

```
ata1: PATA max PIO4 cmd 0x1f0 ctl 0x3f6 irq 14 lpm-pol 0
ata1.00: ATA-6: g86m disk, 1, max PIO4
ata1.00: 65536 sectors, multi 1: LBA48
sd 0:0:0:0: [sda] 65536 512-byte logical blocks: (33.6 MB/32.0 MiB)
/dev/sda on / type ext2 (rw,relatime,errors=continue,user_xattr,acl)
```

- A first run writes a line of text and 3 MB from `/dev/urandom` and prints the MD5; a
  second run prints the same MD5 and the text; `grep` on the host finds the text in the
  image; `e2fsck -fn` on the host passes the file system (334 files, 7,611 blocks) though
  the guest was stopped without unmounting, after a `sync`.
- The interpreter and the JIT take the same 1,329,170,865 instructions through one such
  session, with 3,114 sectors read and 1,400 written.
- The driver worked the first time it was loaded. By the card's second branch all the
  same: without PCI `pata_legacy` goes on to try five more places and asks for interrupt
  lines that are the clock's and the mouse's, which the kernel reports with a stack trace.
  `probe_mask=1` keeps it to the primary channel.

**What was built.** The disk is in `dev.goose`: the task file with two bytes to each of
the count and address registers (the 48-bit commands' upper halves), a buffer of sixteen
sectors, and READ, WRITE, their MULTIPLE and EXT forms, IDENTIFY, SET MULTIPLE MODE, and
the commands that have nothing to do here answered as done; anything else is aborted. A
command is carried out when it is written; the interrupt is raised for each block the host
is to read and after each it has written, and taken back when the status is read. The data
port is one port at every width, which `port_in` and `port_out` (two 8-bit ports to a
word) had to be told. The sectors are in a file that `src/disk.c` reads and writes in
place with `pread` and `pwrite`: thirty lines, the project's third piece of C. `--disk
FILE` attaches it; without it the ports answer as before.

`tools/images/make-disk.sh` makes the two images in a Linux container: an initramfs with
busybox, seven modules from Alpine's modloop of the kernel's own version (`scsi_common`,
`scsi_mod`, `libata`, `pata_legacy`, `sd_mod`, `mbcache`, `ext2`) and an init that loads
them and moves to `/dev/sda` if it holds a root; and a 32 MB ext2 image with the same
busybox and the same init. Neither image is in the repository.

**Tests.** `s_ide` on the bare ports: the signature, the absent slave, IDENTIFY, two
sectors written in one command and the second read back, the registers' earlier bytes, a
sector beyond the end. Eight wrong builds, each caught; one passed at first (a bound one
sector too generous: the file behind the disk refused the read instead, with another
error code, which the test now looks at). The Linux session in `tools/difftest.sh` writes
with the JIT and reads back without it.

**Not done.** DMA; the slave; an ATAPI CD-ROM (which is what rustx86's `ide.rs` is); a
clean shutdown from the guest (`poweroff` has nothing to turn off); the BIOS's INT 13h on
this disk, so DOS does not see it.

## E076: A network (M7) (2026-11-18)

- **Hypothesis**: With a network card Linux drives and a user-mode network stack on the
  host behind it, **`wget https://...` typed at the serial console fetches a page through
  the host**, without root. The parts: the card (a DP8390, as rustx86's `dp8390.rs`), the
  host side (libslirp, the library QEMU uses, as `docs/roadmap.md` chose), and DHCP and
  TLS in the guest (busybox's `udhcpc` and `ssl_client`, which `images/initramfs-mini`
  has).
- **What changed since last time**: Two things are not as the roadmap had them.
  1. The roadmap chose an NE2000 on the ISA bus and put PCI off "until there is a reason".
     The kernel (Alpine's) has no ISA NE2000 driver at all, built in or as a module; it
     has `ne2k-pci`, the same chip on PCI, which is what rustx86 gives it. So there is a
     reason: configuration mechanism 1 (ports CF8h and CFCh), a host bridge and one card,
     as rustx86's `bus/pci`. Only with `--net`: a machine without it has no PCI, and boots
     as it did.
  2. libslirp is reached with `dlopen` when `--net` is given, not linked: Goose's build
     file has no key for a library's directory, and this way a build needs nothing new and
     only `--net` needs the library. The C (`src/net.c`) declares the two structures of
     libslirp's interface it fills in.
  libslirp is the project's third new technology, after Goose and the JIT.
- **Next move for each result**:
  - A page fetched over HTTPS → keep; M7 is done
  - The card is found and DHCP gets no answer → frames counted each way at the card and at
    libslirp, to see which side loses them
  - The driver does not find the card → what the kernel says of PCI, and rustx86's values
    for the same registers
  - Names resolve and TLS fails → the guest's date (E074) and the certificates in the
    initramfs, before the network
- **Cut-off**: A scripted session: DHCP, `ping` of the gateway, `wget` of a page over HTTP
  and over HTTPS, with the page's text checked. It needs the network, so the suite skips
  it when the host has none or libslirp is not there.

### Result

2026-11-18. **Half kept: the network is there and a page comes over HTTP; over HTTPS it
does not, for a reason that is not the network's. M7 is not done.** `tools/difftest.sh` has
133 lines, all ok.

```
pci 0000:00:03.0: [10ec:8029] type 00 class 0x020000 conventional PCI endpoint
ne2k-pci 0000:00:03.0 eth0: RealTek RTL-8029(AS) found at 0xc000, IRQ 3, 52:54:00:12:34:56.
inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
2 packets transmitted, 2 packets received, 0% packet loss       (ping 10.0.2.2)
Name: example.com  Address: 104.20.23.154                        (nslookup, by 10.0.2.3)
<title>Example Domain</title>                                    (wget http://example.com/)
g86m: unimplemented opcode 0F 7e at 0073:b7be1505               (wget https://example.com/)
```

- The card, PCI, DHCP, ARP, ICMP, DNS and TCP all worked the first time they were run,
  with `images/initramfs-mini` as it is (it has `8390`, `ne2k-pci` and `af_packet`).
- **HTTPS stops at an SSE2 instruction.** The opcode is `F3 0F 7E`, `movq (%eax), %xmm0`,
  in `CRYPTO_atomic_load` of the guest's `libcrypto.so.3`: not hand-written code behind a
  test of CPUID (g86m claims neither MMX nor SSE2), but what the C compiler made of a
  64-bit load. Alpine's 32-bit OpenSSL is compiled for a CPU with SSE2: 265 of its
  functions use XMM registers (10,780 instructions), and it has 2,948 MMX instructions
  besides. rustx86 met the same wall and has both (`sse.rs`, 1,163 lines; `mmx.rs`, 478).
  So the card's fourth branch is not what happened: the date and the certificates were
  never reached.
- By the roadmap SSE2 is M10's ("likely the largest part"), and M9's browser, taken from
  the same distribution, will want it as well. The two ways on: MMX and SSE2 in the
  interpreter now (with FXSAVE and FXRSTOR, CR4's OSFXSR, and CPUID saying so, for the
  kernel to let user code use them), or a TLS client for the guest built without SSE2.
  That is a choice about the roadmap, and it is the owner's.

**What was built.** `src/net.c` (190 lines): libslirp opened with `dlopen`, its
configuration and callbacks, a queue of frames for the guest, its timers, and one
`poll()` without waiting each time the run loop asks. In `dev.goose`: configuration
mechanism 1 with a host bridge and the card, whose first base address can be sized and
moved; and the DP8390, after rustx86's. The run loop looks at the network every 40,000
instructions (half a millisecond of guest time) and when the guest is halted; in a run
that nothing else paces (scripted, headless), the time the guest spent halted is slept,
because the other end of the network runs on the host's time. With no `--net` there is no
PCI and no card: the plain boot's count is as E074 left it.

**Tests.** `s_net` on the bare ports: the two PCI devices and an empty one, the size of
the card's ports, the ports off and on, the address PROM, a byte in the chip's memory.
The suite's Linux session gets an address by DHCP and pings the gateway, all inside the
machine; nothing from outside is fetched there. HTTP and DNS were run by hand, against
example.com. No wrong builds were made for this one yet.

## E077: MMX and SSE2, for the guest's TLS (2026-11-18)

E076 left M7 one step short: HTTPS stops at an SSE2 instruction the C compiler put into the
guest's OpenSSL. The owner chose to bring MMX and SSE2 forward from M10.

- **Hypothesis**: The instructions that the guest's `libcrypto`, `libssl`, `ssl_client`,
  musl and busybox contain and that a CPU without SSSE3, AES or AVX is ever sent to (a
  count over their disassembly: moves, the packed integer arithmetic, logic, shifts,
  shuffles and unpacks, a few conversions and scalar doubles), with FXSAVE and FXRSTOR,
  LDMXCSR and STMXCSR, and CPUID saying MMX, FXSR, SSE and SSE2, are enough: **the kernel
  turns the registers on, and `wget https://example.com/` prints the page's title.**
- **What changed since last time**: A new part of the CPU, on the general path only: the
  short executors and the JIT do not know these instructions and need not. The XMM
  registers are two 64-bit words each; the MMX registers are the FPU registers' mantissas,
  as on the chip, which `fp_mant` already holds. Floats are the host's, as rustx86's are:
  no exception is raised and MXCSR's rounding mode is not obeyed.
- **Next move for each result**:
  - The title printed → keep; M7 is done
  - The kernel does not boot once CPUID says FXSR → FXSAVE's and FXRSTOR's layout against
    the manual and against rustx86, before any other instruction
  - TLS fails with a bad record or a bad signature → an integer instruction is wrong: the
    test of each against rustx86's trace, in the order of the count
  - An opcode is still missing → it is added; the count was of what is there, not of what
    runs
- **Cut-off**: A trace test of the instructions against rustx86 (`v_sse`), the suite, the
  boot's count with the new CPUID, `wget` over HTTPS by hand.

### Result

2026-11-18. **Kept: `wget https://example.com/` prints `<title>Example Domain</title>`, and
`https://www.kernel.org/` comes whole (20,436 bytes). M7 is done.** `tools/difftest.sh` has
146 lines, all ok.

- The kernel says `x86/fpu: x87 FPU will use FXSAVE`, and `/proc/cpuinfo` has `fxsr mmx
  sse sse2`. The page came the first time the new instructions were run; nothing in the
  card's second, third or fourth branch happened.
- The plain Linux boot's count is 1,492,980,001 (1,492,760,001 before CPUID said more), the
  same with `--jit` and without.

**What was built.** `src/sse.goose`, 798 lines, called from `two_byte` for a third of the
two-byte opcodes on the i686 and for nothing else: the XMM registers as two words each, the
MMX registers as the FPU registers' mantissas, the packed integer instructions once for
both (a word at a time), the moves, shuffles and unpacks, conversions, single and double
arithmetic and comparison, FXSAVE and FXRSTOR, LDMXCSR and STMXCSR. CPUID's leaf 1 says
MMX, FXSR, SSE and SSE2. Not built: SSE3 and later (CPUID does not say them), MASKMOVQ,
exceptions and MXCSR's rounding mode.

**Against rustx86: 306 cases in eleven trace tests (`v_sse01` to `v_sse11`), written by
`tools/gen_sse_tests.py`; all the same, line for line.** Each case leaves its result in
XMM0 or MM0 and loads it into four registers, which the trace shows. On the first run 299
of 312 cases agreed. Of the rest, one was g86m's:

- **Floats that are not numbers.** The smaller of a number and a NaN came out as the number
  in three lanes of four, where the chip gives the second operand. The comparison was
  written as `if a < b { a } else { b }`, which is the chip's rule only if a comparison
  with a NaN is false, and the compiled code did not keep to that. Arithmetic on singles
  and doubles now looks at the bits first (`far32`, `far64`): the chip's rules for which
  operand comes out, and the "real indefinite" with its sign set for a result that is no
  number, which on this host has its sign clear.

**And five were rustx86's**, where g86m does what Intel's manual says. They are in the
self-check `s_sse`, against the manual's values, and out of the trace tests:

| Instruction | The manual, and g86m | rustx86 |
|---|---|---|
| CVTSS2SI, CVTSD2SI, CVTPS2DQ, CVTPD2DQ, CVTPS2PI, CVTPD2PI | round to nearest, a half to the even number: -3.75 gives -4 | cut off: -3 |
| MOVHLPS | the source's high half | its low half |
| FNSTENV in 16-bit code | fourteen bytes, the tags at byte 4 | twenty-eight, the tags at byte 8 |
| The square root of a negative number, 0 / 0 | FFC00000h, the sign set | 7FC00000h, the host's |
| MINPS and MAXPS with a NaN | the second operand | the number |

**Twenty-one wrong builds, each caught**; four passed at first (the smaller and the larger
with the operands' order turned, the abridged tags of FXSAVE inverted, an MMX register's
exponent, the stack's top after an MMX instruction), and got a case each.

**Besides.** `tools/oracle/trace32.rs` was copied into the rustx86 checkout and built
there, as `tools/difftest.sh` says to; the copy is an untracked file in that repository.

## E078: A screen (M8) (2026-11-18)

- **Hypothesis**: Three parts make M8: a frame buffer the kernel draws on, a window on the
  host that shows it and takes the keyboard and the mouse, and X in the guest. **`startx`
  typed at the serial console brings up X in a window on the host: an xterm that can be
  typed into and a pointer that follows the mouse.**
- **What changed since last time**: Again the roadmap's choice of device does not survive
  a look at the kernel. It named the Bochs VBE interface, for `bochs-drm` or `vesafb`.
  rustx86's loader says what the kernel (Alpine's) has built in: `efifb` and `fbcon`, and
  neither of those two. So there is no device at all: the loader declares a linear frame
  buffer in the boot parameters (`screen_info`, as a boot loader that had asked the
  firmware would), as the top of RAM, reserved in the memory map, in a pixel format that
  the kernel's table of simple frame buffers does not have, so that `efifb` takes it. All
  of that is rustx86's finding and is taken as it is. The window is SDL2, which the README
  named from the start; like libslirp it is opened with `dlopen` when asked for. The mouse
  is a PS/2 one on the 8042's second port, after rustx86's `mouse.rs`. The guest's X is
  the tree rustx86's X disk is made of (Alpine's Xorg with the fbdev driver, icewm, xterm,
  dillo), put on an ext2 image for the IDE disk of E075; the roadmap's Xfbdev and twm
  built with Buildroot are not needed for it.
- **Next move for each result**:
  - X up, typed into, the pointer moves → keep; M8 is done
  - The kernel's console does not appear on the frame buffer → the boot parameters'
    fields against rustx86's, byte for byte, before the window is suspected
  - The console appears and X does not start → `/var/log/Xorg.0.log` in the guest
  - X starts and an instruction is missing (X is compiled like OpenSSL) → it is added
    to `sse.goose` with a case in the trace tests
- **Cut-off**: A scripted run that boots with the frame buffer and saves it as an image
  (`--shot`), compared without a window: the kernel's console is on it. X and the window
  by hand, with a saved image of X as the record.

### Result

2026-11-18. **Kept, with one part left for a hand: `startx` at the serial console brings up
X (Xorg, icewm, an xterm) on the frame buffer; a line typed at the keyboard runs in the
xterm; the pointer follows the mouse. All of that is shown by scripted runs that save the
frame ([docs/img/m8-x.png](img/m8-x.png)). The window opens, shows the frame buffer and
closes cleanly; typing and moving the mouse *in the window* have not been tried, because
a script cannot press a key there.** `tools/difftest.sh` has 150 lines, all ok.

```
efifb: framebuffer at 0x7d00000, using 3072k, total 3072k
efifb: mode is 1024x768x32, linelength=4096, pages=1
Console: switching to colour frame buffer device 128x48
fb0: EFI VGA frame buffer device
serio: i8042 AUX port at 0x60,0x64 irq 12
input: PS/2 Generic Mouse as /devices/platform/i8042/serio1/input/input3
```

- The kernel's console was on the frame buffer the first time it was run with one.
- The mouse's port was not found at first: the driver proves the second port and its
  interrupt by sending a byte round it (controller command D3h), which was not there.
- X needed nothing new in the CPU: the instructions of E077 were enough.
- From `startx` to the desktop is about ninety seconds of guest time on a fresh copy of
  the disk; the first two saved frames were black because they were taken at thirty.
- Scripted typing lost characters in X: `echo typed-in-x > /tmp/k; uname -a` arrived as
  `echo  uname -a`. A script types as fast as the keyboard controller is read, two thousand
  keys a second, and what reads the keyboard through the kernel's event queue drops what
  it cannot take. `--keys` now types fifty a second of the guest's time.

**What was built.** In `linux.goose`, `--fb WxH`: the top of RAM taken out of the memory
map and declared in the boot parameters as rustx86 does it. `src/screen.c` (170 lines):
SDL2 opened with `dlopen`, a streaming texture the frame buffer is copied to thirty times
a second, and the window's events turned into scan codes, mouse movement and buttons; a
click takes the pointer and Ctrl+Alt gives it back. In `dev.goose`, the 8042's second
port and a three-button PS/2 mouse. For scripts and tests: `--shot FILE` saves the frame
as a PPM, `--keys TEXT` types at the keyboard where `--type` goes to the serial port, and
`--mouse X,Y,B` moves the mouse. `tools/images/make-x-disk.sh` puts the tree of rustx86's
X disk on a 320 MB ext2 image with g86m's init.

**Tests.** `s_mouse` on the bare ports. In the suite: a boot with the frame buffer whose
saved frame has the console on it; and X from the disk, a line typed into the xterm that
leaves a file the serial console reads, and thirty bytes counted from the mouse. No wrong
builds were made for this one.

**Open, and not M8's: with `--jit`, once X runs, the kernel's watchdog marks the TSC
unstable** (`'tsc' skewed 632088 ns over watchdog 'pit' interval of 503369980 ns`) and
goes on with another clock source. Without `--jit` it does not; a boot without X, with
the JIT, runs ninety seconds of guest time without it; none of five `--jit-off` bits
(RDTSC in blocks, the kinds of E073, the far way, the look ahead, linking) takes it away.
632 microseconds are 48 thousand instructions. So the time that generated code reports,
or the time the timer sees, is off by that much somewhere under a load the boot does not
have. Nothing has gone wrong because of it that was seen. It is task 15 of `docs/jit.md`.

## E079: A browser (M9) (2026-11-18)

- **Hypothesis**: Everything M9 needs is there since E078: the X disk has Dillo, the
  network of E076 carries HTTPS, and the CPU has what Alpine's binaries are compiled for.
  What is missing is small: the disk's init does not bring the network up. With the card's
  driver loaded and `udhcpc` run there, **`dillo https://example.com/` in X shows the
  page: its heading is on the saved frame.**
- **What changed since last time**: Nothing in the machine. The init of
  `tools/images/init` learns the network, for both roots.
- **Next move for each result**:
  - The page on the frame → keep; M9 is done
  - Dillo stops at an instruction → it is added, with a case in the trace tests (E077's
    fourth branch)
  - Dillo runs and shows an error page → its message: name resolution, the certificate
    (the guest's date is 2026-01-01 in a scripted run: `--rtc host`), or its HTTPS helper
  - Dillo does not fit in 128 MB with X → what `free` says, before more memory is given
- **Cut-off**: One scripted run with `--net --rtc host --fb`, the frame saved. It needs the
  world, so it is not in the suite.

### Result

2026-11-18. **Kept: Dillo, in X, shows `https://example.com/`
([docs/img/m9-dillo.png](img/m9-dillo.png)). M9 is done.** By the card: its first branch.

- The window's title is "Dillo: Example Domain" and the page's paragraph is on the frame.
  The page's heading is not: the title bar has its text, the page area does not show it
  (the card said the heading would be on the frame; what is there is the title and the
  body). Whether Dillo leaves it out of this page on real hardware too was not looked at.
- Dillo's log names the certificate chain it checked (Cloudflare's issuing CA up to
  Comodo's root), with the guest's clock at the host's time (`--rtc host`).
- No instruction was missing. With X, icewm, an xterm and Dillo, 31 of 103 MB are used.
- The run: 13.0 billion guest instructions, 130 seconds on the host (the network's idle
  time is slept), 145,570 sectors read from the disk.

**What was built.** Fourteen lines in `tools/images/init`: on either root, the network
card's driver is loaded if the root has the modules, and `udhcpc` is run in the background
if the card is there. Nothing in the machine changed.

**Not in the suite**: the run needs the world. The suite's X session (E078) is as it was.

## E080: Where 632 microseconds go (2026-11-18)

Task 15 of `docs/jit.md`, left open by E078.

- **Hypothesis**: The kernel's two readings in the warning are 52 thousand instructions
  apart over half a second: the PIT's time ran that much more than the TSC's in one case
  and less in another, so it is jitter and not drift. The PIT's time as the kernel reads it
  is the count of interrupts taken times the period, plus the counter's place in the
  period. The counter's period starts anew where the interrupt is *raised*
  (`timer_fire`: `timer_at = vtime + period`), so an interrupt raised late moves every
  later period by its lateness. A run is planned to stop at `timer_at` exactly; **if with
  the JIT a step can run past the moment it was given (`chain_until`) by tens of thousands
  of instructions, `timer_fire` sees it as lateness, and a count of it shows steps of that
  size only with `--jit` and X.**
- **What changed since last time**: E078 tried `--jit-off` bits, which answer "which
  translation"; this asks "does virtual time pass the plan at all", which no bit turns off.
- **Next move for each result**:
  - Lateness of thousands of instructions with the JIT and none without → where the time
    was given: the count of instructions a call into generated code returned against the
    time it was allowed, at the call that passes it
  - No lateness beyond a few instructions either way → the periods are right and it is
    the reading: what `pit_count` returns around the moment of the interrupt, next
- **Cut-off**: One counting build (the largest lateness and how many above a thousand,
  printed at the end), run twice: with `--jit` and X to the warning, and without `--jit`.

### Result

2026-11-18. **The hypothesis is wrong, and so was E078's "with `--jit` only".** The timer
is never late: over a boot with X, the largest lateness `timer_fire` saw is 0, and no call
into generated code ran past the time it was given. And the same counting run without
`--jit` printed the warning too: E078 had concluded from one run each way.

By the card's second branch, the reading. A second count:

| A boot of 7 billion instructions, with `--jit` | With X | Without (no disk) |
|---|---:|---:|
| The kernel marks the TSC unstable | yes | no |
| Channel 0's count written by the guest | 61,563 times | 14,119 times |
| The timer's interrupt raised while the one before still waited | 146 | 0 |

**The kernel does not leave the timer periodic.** It writes channel 0's count for every
event it wants, tens of thousands of times in a boot. Its reading of that same counter as
a clock ("pit": interrupts counted, times the period, plus the counter's place in the
period) means nothing once the periods are of its own making, and it is against that
reading that its watchdog checks the TSC, because this machine has no third clock (no
HPET, no ACPI timer). An idle boot's events are regular enough for the two to agree by
luck; X's are not. Nothing in the emulator's timer is off.

**So the kernel is told: `tsc=reliable` is in the default command line.** The TSC here is
the instruction count, the very thing the timer runs on. With it, X runs ninety seconds
of guest time with no warning, the clock source stays `tsc`, and `pit` is no longer among
those available. A command line given with `--append` is used as it is, as before.

The plain Linux boot's count is 1,496,360,001 with the new default (1,492,980,001), the
same with `--jit` and without. `tools/difftest.sh` has 150 lines, all ok.

**What this cost and what it was.** Three counting runs and two cards' worth of looking in
the wrong place (the JIT's bits in E078, lateness here), for a line of the kernel's log
that the numbers in it would have explained sooner: the TSC's interval in the warning is
504.000 ms, a whole number of ticks to within thirty instructions, and the PIT's is 504.67.
The clock that was off was the one being trusted. Task 15 of `docs/jit.md` is closed as
not the JIT's.

## E081: A disk that an unclean stop cannot break (2026-11-18)

- **What happened**: The owner ran X from `images/disk-x.img`, left with Ctrl-], and the
  next boot could not use the disk: `EXT2-fs (sda): error: ext2_lookup: deleted inode
  referenced: 40961`, no `/dev`, `sh: can't open /dev/ttyS0` for ever. `e2fsck -fn` on the
  host: "Filesystem still has errors". The guest writes the image in place (E075), ext2
  has no journal, the init writes on every boot (busybox's links), and there is no way to
  stop the machine from inside (E075's "not done"). So every way out was an unclean one.
- **Hypothesis**: Two things, either of which would have prevented it. `--scratch`: the
  disk's writes are kept in memory and the image is never changed, which is what trying X
  wants. And a clean way out for when the writes are wanted: a command in the guest that
  syncs, makes the root read-only and powers off, at which the emulator stops. **With
  `--scratch`, an image is byte for byte the same after a session that wrote to it and was
  cut off; with `off` in the guest, g86m exits by itself and `e2fsck` passes the image.**
- **What changed since last time**: E075 tested persistence with `sync` and a kill, and
  `e2fsck` passed by luck of where the kill fell.
- **Next move for each result**:
  - Both hold → keep; the README says which to use when
  - The kernel does not halt on `poweroff -f` → what it does instead, from the serial log
- **Cut-off**: A checksum of the image before and after a scratch session; `e2fsck -fn`
  after `off`; both in the suite.

### Result

2026-11-18. **Kept: both hold.** `tools/difftest.sh` has 151 lines, all ok.

- `--scratch`: the image is mapped privately (`mmap`, `MAP_PRIVATE`), so a write changes a
  page of this process and never the file. An image's checksum is the same after a session
  that wrote 2 MB to it and was cut off.
- `off` in the guest (`/bin/off`, put on both roots by the image scripts): `sync`, the root
  remounted read-only, `poweroff -f`. The kernel says `reboot: Power off not available:
  System halted instead` and halts with interrupts off, which the run loop has always
  taken as the end: g86m exits by itself. `e2fsck -fn` on the host then passes the image,
  and the next boot mounts it without the kernel's "unchecked fs" warning.
- The owner's broken image was kept as `images/disk-x.broken.img` and a new one made.

**What this was.** E075 called the disk done with "a clean shutdown from the guest" under
"not done", and E078 handed the owner a writable ext2 root with Ctrl-] as the only way
out. The first unclean stop that fell badly broke it. What "not done" lists is not always
what can wait.

## E082: A console is not cut off at twenty billion instructions (2026-11-18)

- **What happened**: The owner started X at `--speed 4`, started Dillo, and g86m ended with
  `steps 20001160660 halted true`: taken for a crash. It is the default `--max`. Twenty
  billion instructions are four minutes of guest time at the default speed and one at
  `--speed 4`; a session with X in it is longer than that.
- **Hypothesis**: The limit is there so that a run nobody watches does not go on for ever.
  A console is watched. **Without `--max`, a console runs until it is left; with it, it
  stops there and says so.**
- **What changed since last time**: Sessions were short until X.
- **Next move for each result**: holds → keep. A console that still ends by itself → what
  the last line says, since the limit now names itself.
- **Cut-off**: Two runs in a pseudo-terminal: one past twenty billion, one with `--max`.

### Result

2026-11-18. **Kept.** A console at `--speed 8 --unpaced` was at 39.8 billion instructions
when it was left with Ctrl-], and said nothing of a limit; with `--max 3000000000` it
stopped at three billion and wrote `g86m: stopped at the limit of --max instructions`.
Scripted and headless runs keep the default.

`tools/difftest.sh`: 151 lines, all ok, on its second run. The first had 150 and one
failure, X, and not because of this change: the owner's session that met the limit had been
run without `--scratch`, the limit is as unclean a stop as Ctrl-], and `images/disk-x.img`,
which the suite copies, was broken a second time. It was made again. Twice in an hour is
the case for keeping the image unchanged unless asked: a question put to the owner.

That makes three things a first real session found that the scripted ones could not: the
disk broken by an unclean stop (E081), this, and whatever typing in the window turns up.

## E083: A closed connection must not end the machine (2026-11-18)

- **What happened**: The owner opened a page with many images in Dillo (`--net`, in the
  window) and g86m was gone: no message, no line of statistics. Dillo's log just before:
  `IO_write, closing with pending data not sent: "GET /wp-content/uploads/...`.
- **Hypothesis**: Not a fault of g86m's own, which the system would have recorded (there is
  no crash report), and not one of its ways of stopping, which all print the line of
  statistics. A process that ends with neither was ended by a signal it did not handle.
  libslirp writes to the host's sockets on the guest's behalf; a write to a connection the
  other end has closed raises SIGPIPE, whose default is to end the process silently; and
  the browser's log shows connections being closed with requests still unsent. **With
  SIGPIPE ignored, such a write fails with an error, which libslirp handles, and the
  machine goes on.**
- **What changed since last time**: E076 and E079 fetched one page over one connection. A
  page with thirty images is the first use that closes connections while others are busy.
- **Next move for each result**:
  - The owner's session survives the same page → keep
  - It ends again → the shell's `$?` after it (141 is SIGPIPE; anything else names another
    signal), since the cause was inferred and not seen
- **Cut-off**: The fix is one line and is right whatever else is wrong. The same page
  fetched in a scripted run, which had not failed before either: that run cannot confirm
  the cause, only that nothing broke.

### Result

2026-11-18. **Applied; the cause was inferred first and shown after (below).** `signal(SIGPIPE, SIG_IGN)` where
libslirp is opened. A scripted run of X and Dillo on the same site, without a window, had
ended normally before the change too (19.9 billion instructions, 253 frames out and 269
in), so it shows nothing about the cause. What would show it is the owner's session.

**Shown, afterwards.** The owner's shell, asked after the session that had ended: `echo $?`
gave 141, which is 128 plus 13, SIGPIPE. The card's second branch named that number as
what would tell; it came from the run before the fix, and confirms the cause. With the fix,
the owner opened the same page again and the machine stayed up.

## E084: The image is not changed unless asked (2026-11-18)

- **What happened**: `images/disk-x.img` was broken twice in an hour (E081, E082): by
  Ctrl-], and by the limit of `--max`. `--scratch` and `off` were there after the first
  time; the second session used neither, because the command line that had been given
  before did not.
- **Hypothesis**: A safeguard that has to be asked for is not used the first time it is
  needed. Turned round: **`--disk FILE` alone never changes the image, however the run
  ends; `--keep` is what writes it, and then `off` is the way out.** The owner chose this.
- **What changed since last time**: E075 made writing in place the default because M6's
  condition was a file system that is written. It still is, with `--keep`.
- **Next move for each result**: holds → keep. A use that needed the old default without
  saying so → it gets `--keep` (the suite's own, here).
- **Cut-off**: The suite: an image unchanged after a session that wrote and was cut off,
  with no option; writes kept and a clean file system after `off`, with `--keep`.

### Result

2026-11-18. **Kept.** `--scratch` is still accepted and now says what is the case anyway.
Two sessions of the suite got `--keep`: the one that writes 2 MB and reads it back in a
second run (E075), and the one that leaves with `off` (E081). `tools/difftest.sh` has 151 lines,
all ok. By hand: an image's checksum is the same after a session without `--keep` wrote 3 MB
and was cut off.

## E085: Where the time goes when X runs (2026-11-19)

A count before any change, as E067 was for the boot. The owner's plan: make X on the
32-bit machine quick with what will carry over to x86_64, then go to x86_64.

- **Hypothesis**: The boot's profile (E073: 98% of the instructions in blocks, 11 million
  trips) is not X's. X and what it draws with are compiled for SSE2, which the JIT does
  not know and the interpreter runs on its general path, the slowest there is; and X moves
  much memory with string instructions. **During X's start and while it draws, a third or
  more of the host's time is the general path, and MMX and SSE instructions are most of
  what it executes there.**
- **What changed since last time**: Every count so far was of the boot to the first prompt.
- **Next move for each result**:
  - As said → the MMX and SSE instructions get a faster road first (which carries over to
    x86_64 whole); by the list of which
  - The general path is large and they are not most of it → the list says what is
  - Generated code is nine tenths again → the JIT's own costs under X's code (ways out,
    the far way finding nothing), counted as E067 did
  - The host's time is not in the CPU at all (the disk, the window) → that, first
- **Cut-off**: One counting build (the general path's instructions by opcode, and how many
  instructions each road executes), run to three points: the prompt, X's desktop, and
  after a terminal has scrolled and Dillo has drawn a page from the disk. One `sample` of
  the second and of the third stretch. No window: the frame buffer is memory either way.

### Result

2026-11-19. **The hypothesis is wrong: MMX and SSE are 3% of what the general path executes
while X starts and 1% or less of the host's time. What is true of X is what was true of
the boot before E067: half the time is trips between generated code and Goose.**

| Stretch (guest time includes idle) | Guest instr. in blocks | On the general path | of them MMX, SSE | Entries into generated code | Far way | Host |
|---|---:|---:|---:|---:|---:|---:|
| Boot to the prompt | 1.45 billion | 19.1 million | 0.2 million | 14.1 million | 20.4 million | 2.9 s |
| `startx` to the desktop (90 s of guest time) | 3.09 billion | 118.7 million | 3.6 million | 90.0 million | 119.0 million | 12.5 s |
| A terminal scrolling, Dillo drawing a table (45 s) | 1.57 billion | 74.1 million | 7.1 million | 51.1 million | 72.6 million | 8.0 s |

- Generated code is entered once for 34 guest instructions under X; once for 103 in the
  boot. The host gets through 250 million guest instructions a second in X and 500 in the
  boot. At the default speed the guest is a CPU of 76 million a second, so X is slow
  because the guest is; at `--speed 4` (305 million) the host cannot keep up with X.
- A sample of the host while X starts (6,556 samples): generated code about 46%,
  `exec_short` 16%, `exec_general` 13%, `exec_one` (with `jit_blocks`) 11%, `string_op`
  2%, `two_byte` 2%, `sse_op` 0.3%. While it draws: about 50%, 15%, 14%, 9%; `sse_op` 1%.
- The disk and the frame buffer are not in it: `ide_read` 0.6%.

**What the general path executes while X starts, in millions** (each is a trip):

| Instructions | Count | Why they are there |
|---|---:|---|
| Group FF: indirect CALL and JMP, `push r/m` | 12.5 | CALL and JMP through a register or memory have no kind; shared libraries call through tables |
| `cmp r/m, r` (39), group 83, `mov` (89, 8B), C7, group 81 | 23.0 | have executors; here for a reason not yet counted (a prefix, more than eight bytes, the page's last bytes) |
| CMOVcc (0F 40 to 4F) | 6.4 | no kind |
| IMUL by a constant (6B, 69) | 4.7 | no kind |
| BT, BTS, BTR, the BT group | 3.9 | no kind |
| XCHG of a byte with memory (86) | 3.4 | no kind |
| SHLD, SHRD | 2.6 | no kind |
| REP MOVSB and the other strings with REP | 4.9 | REP has no kind |
| PUSHF, CLI | 3.0 | no kind |
| CMPXCHG | 1.9 | no kind |
| INC and DEC of a byte (FE), shifts (C1) by the long way | 3.7 | |
| An executor's instruction run by the general path because the run had no time or the entry was a block | 22.4 | |

By the card: the second and third branches together. The plan that follows from it is
[docs/perf.md](perf.md).

## E086: Why instructions with executors reach the general path (2026-11-19)

P2 of `docs/perf.md`, its first half: a count.

- **Hypothesis**: 23 million executions of `cmp`, `mov` and the immediate groups are on
  the general path while X starts, though `classify` knows those opcodes. Each has a reason
  that can be read where the general path decodes it: no entry could be made (the page's
  last bytes, a limit), the entry is new (first and second execution), or `classify`
  refused it (a 16-bit operand, LOCK, REP, more than eight bytes, a form it leaves out).
  **One or two reasons are most of the 23 million, and they are refusals, not new
  entries.**
- **What changed since last time**: E085 counted by opcode; this by reason.
- **Next move for each result**:
  - More than eight bytes is the largest → `classify` reads the immediate from memory
    beyond the eighth byte
  - A 16-bit operand is the largest → 16-bit forms of the commonest kinds, in the
    translator only
  - New entries are most → the decode cache is being emptied: by what (stores into pages
    of code, slots fought over), counted next
- **Cut-off**: One counting build, one run from the prompt to the desktop.

### Result

2026-11-19. **Half right: one reason is large, and so are two that are not refusals.** Of
the general path's 118.7 million instructions from `startx` to the desktop, in millions:

| Why | All | `cmp`, `mov`, `add`, `test`, the immediate groups |
|---|---:|---:|
| Refused by `classify` for its form (no kind for the opcode) | 50.4 | 2.3 |
| No entry possible: the instruction is in the page's last fifteen bytes | 17.6 | 8.4 |
| A 16-bit operand (prefix 66) | 16.2 | 12.2 |
| No entry yet (a first execution) | 6.8 | 2.9 |
| REP | 4.9 | |
| LOCK | 0.4 | |

(The 22.4 million executions of an executor's instruction by the general path are not in
these: they are counted before this point.)

- **The page's last fifteen bytes.** An instruction that begins there gets no entry, ever,
  because a cached instruction's bytes are read sixteen at a time from one page. One
  instruction in 270 begins there; a loop that has one pays a trip every time round.
- **16-bit operands.** `cmp`, `test`, `add` and the immediate groups with prefix 66: only
  MOV has 16-bit kinds.
- **First executions**: 6.8 million in ninety seconds is the decode cache losing entries
  to other addresses (131,072 slots, one address each) faster than the boot ever did.
- More than eight bytes is not it: 0.06 million.

`docs/perf.md` has these as P2a, P2b and P2c.

## E087: Indirect CALL and JMP, and CMOV, in blocks (2026-11-19)

P1 and P3 of `docs/perf.md`.

- **Hypothesis**: An indirect CALL or JMP (FF /2, /4) is a jump whose target is known
  only when it runs, as a RET's is, and the far way exists for that (E069): the block ends
  there, with the target read, the return address pushed for a CALL, and the far way
  finding the next block. CMOVcc is a condition, as SETcc has it, and a select. Together
  they are 19 million trips of the stretch from `startx` to the desktop, and each indirect
  call that stays in generated code lets what follows it stay too. **Generated code is
  entered 70 million times in that stretch (90 before), and the host takes 10% less time
  for it.**
- **What changed since last time**: E073's kinds were straight-line instructions; these two
  end a block at an address not known to the translator.
- **Next move for each result**:
  - Both as said → keep; P2a next (the page's last bytes)
  - Entries fall and the time does not → the far way's own cost is what was bought: P7
    (prediction) moves up
  - A test fails with `--jit` only → `--jit-off 262144` turns these off; halve
- **Cut-off**: A self-check (calls and jumps through a register and through memory, into
  another page and back; CMOV on every condition, taken and not, from a register and
  from memory, summed against a trace run), wrong builds, the suite, the stretch timed
  five times each way.

### Result

2026-11-19. **Kept: from `startx` to the desktop, generated code is entered 73.1 million
times (90.0) and the host takes 11.20 seconds (12.26, 8.6% less).** The card said 70
million and 10%: close to both; its first branch. The guest executes the same
8,380,137,681 instructions of virtual time to that point before and after.

| `startx` to the desktop, medians of three | Entries | The far way finds a block | Host |
|---|---:|---:|---:|
| Before | 90.0 million | 119.0 million | 12.26 s |
| Indirect CALL and JMP, CMOV | 73.1 million | 136.3 million | 11.20 s |

That is 280 million guest instructions a second of the host under X, where `--speed 4`
wants 305.

**What was built.** Three kinds, 110 to 112. An indirect CALL or JMP ends its block: the
target is read into x27 (which the push does not use), a CALL pushes its return address as
`K_CALL` does, and the far way takes the target. CMOVcc takes the condition as SETcc does,
reads its source whether the condition holds or not, and selects with `csel`.
`--jit-off 262144` turns them off.

**Tests.** `s_jitind`: calls and jumps through a register and through memory, to this page
and to a function above 64 KB, over instructions that must not run, in a code segment
whose base is 1000h; CMOV on sixteen conditions from a register and from memory.
`tools/difftest.sh` has 153 lines, all ok. Ten wrong builds, each caught; two passed at
first. A target loaded as sixteen bits is the same below 64 KB; and a target taken as an
address where it is an instruction pointer is the same where the code segment's base is
0, which it was in every self-check of the JIT's but `s_csbase`.

## E088: Instructions in a page's last fifteen bytes get an entry (2026-11-19)

P2a of `docs/perf.md`.

- **Hypothesis**: An instruction that begins in a page's last fifteen bytes has no entry in
  the decode cache because an entry's fetches are plain loads from the page, and nobody
  knows before decoding whether the instruction ends in it. Most do end in it. With a
  function that tells an instruction's length from its first bytes, such an instruction
  gets an entry when it ends in the page, runs and blocks reach the page's last byte, and
  the 17.6 million trips E086 counted for these go. **Generated code is entered 58
  million times from `startx` to the desktop (73.1 now), the host takes less time for it,
  and the interpreter without `--jit` is no slower.**
- **What changed since last time**: E087 gave kinds to instructions that had none. This
  gives entries to instructions that have kinds already; it changes the decode cache,
  which the interpreter shares.
- **Next move for each result**:
  - Entries and time both fall, the interpreter the same → keep; P2b next (16-bit operands)
  - Entries fall and the time does not → what an entry costs is the matter: P8's count
    moves up before P2b
  - Entries do not fall → E086's count named the wrong cause, or the length function says
    "not known" for what is there: count the instructions that still begin in the tail by
    opcode, and by whether they end in the page
  - The interpreter is more than 1% slower on the Linux boot → not kept in this form; the
    test goes where only a miss pays for it
- **Cut-off**: The length function checked against what the general path fetches, on every
  instruction of a Linux boot and of X's start (a counting copy); a self-check with
  instructions that end at a page's last byte and that cross it; wrong builds; the suite;
  the stretch timed three times each way.

### Result

2026-11-19. **Kept, by the card's first branch for the time and its third for the entries:
from `startx` to the desktop the host takes 10.96 seconds (11.72 before, in the same
sitting; 6.5% less), and generated code is entered 72.1 million times (73.1), not the 58
million the card said.** The interpreter without `--jit` is the same: 26.2 billion host
cycles for the Linux boot before and after (three runs each), and 0.4% fewer host
instructions.

| Medians of three, one sitting | Entries | Instructions in blocks | The far way finds a block | Host |
|---|---:|---:|---:|---:|
| Boot to the prompt, before | 13.98 million | 1,453 million | | 2.92 s |
| Boot to the prompt, after | 13.79 million | 1,455 million | | 2.88 s |
| To the desktop, before | 87.11 million | 4,565 million | 156.8 million | 14.64 s |
| To the desktop, after | 85.91 million | 4,582 million | 161.4 million | 13.84 s |

The stretch from `startx` to the desktop is the difference of the two stages. (E087's
table said 11.20 seconds for the same build that is 11.72 here: another sitting. Only
numbers of one sitting are compared.)

**The card's number was wrong, and so was the column it came from.** E086 counted
*instructions* that reach the general path, by reason, and `docs/perf.md` wrote them down
as *trips*. The 17.6 million were instructions; several in a row share one trip, since a
block that stops before the page's end is left once and the general path then runs what is
left of the page. What the change did is what the count says: about 14 million instructions
left the general path (the tail's share of it is 3.2 million now, for the whole run, boot
included), 16 million more are executed in blocks, the far way is arrived at 4.6 million
times more (a block now runs to the page's end and goes on from there), and 1.2 million
entries went. The time fell more than the entries because an instruction on the general
path is dear whether or not a trip comes with it. The column in `docs/perf.md` is renamed,
and P8's count is to be of trips by what ended the block, not of instructions.

**What is left in the tail** (the whole run to the desktop): 1.9 million executions of
instructions that cross into the next page, of which 1.08 million are a CALL (E8), and 1.3
million of instructions with an entry and no kind, of which 1.26 million are IMUL by a
constant (6B; P4).

**What was built.** `ins_len` (`src/exec.goose`): the length of an instruction from its
first eight bytes, for 32-bit addressing, or 0 for "not known" (MMX and SSE, far calls and
jumps, ENTER, and what the count below did not meet). In a page's last fifteen bytes the
general path makes an entry only for an instruction that `ins_len` says ends in the page;
a run's bound in the page is its last byte (FFFh, was FF0h); `classify` makes no pair
whose jump does not end in the page. 16-bit code is as before. The JIT needed nothing:
a block that ends at the page's end leaves by the far way already (`jit_leave`).

**The length function checked.** A counting copy compared what `ins_len` said with how far
the general path fetched, for every instruction met a first time in a run to the desktop:
57,318,755 the same, 54 where less was fetched (an instruction that faulted before its
immediate), none where more was fetched, 47,801 not known (all MMX and SSE but `ins` with
104). With `--jit`: 9,283,152, 41, none, 16,936.

**Tests.** `s_pagetail`: a function of two dozen instructions copied so that it ends from 1
byte to its own length past the end of a page, called twelve times at each place, with
paging on and the next page elsewhere in RAM. The first version had no paging and seven of
fourteen wrong builds passed it: without paging the page after in RAM is the page after,
and a fetch of four bytes across the end reads the right bytes. Fourteen wrong builds now
(a length short by an immediate, by a displacement, by a SIB byte; an entry for whatever is
in the tail; the pair made regardless): thirteen caught, with `--jit` and without. The
fourteenth takes out `classify`'s own test that the instruction ends in the page, which
nothing can reach while the test at the entry's making stands; it is left in as the second
line.

`tools/difftest.sh` has 155 lines, all ok (`s_pagetail` is two of them, with the debug
build and without; it is also among the self-checks run with `--jit`).

## E089: What ends a trip (2026-11-19)

P8 of `docs/perf.md`, before P7.

- **Hypothesis**: E086 counted instructions and called them trips (E088). A trip is one
  return from generated code to Goose, and each return has a reason that can be read where
  it comes back: through a link slot to an address with no block, through a way out (an
  instruction in the block gave up when it ran, or the block stopped before one it could
  not take), or from the far way not finding a block. **More than half of the returns under
  X are the far way not finding a block or a slot whose target has none, and of those most
  stand before an instruction the translator has no kind for**; if so P7 (prediction) saves
  host instructions for each arrival and does not save trips.
- **What changed since last time**: E085 and E086 counted on the general path's side.
  This counts on the JIT's side, one count for each return.
- **Next move for each result**:
  - As said → P7 is judged by host time alone, and the instructions without a kind are
    written down for the 64-bit count
  - Most returns are ways out taken while running (the TLB, a segment's top) → P7 still;
    the note for x86_64 is that the memory path wants looking at first there
  - Most returns are to addresses that could head a block and do not yet (cold, or the
    decode cache lost the entry) → look at `JIT_HOT` and at where arrivals are counted
    before P7, since that is a few lines and carries over whole
- **Cut-off**: one counting copy, two stages (the prompt and the desktop), one run each:
  the counts are of events, not of time.

### Result

2026-11-19. **The card's first branch, and something it did not ask about: 27% of the
returns are the TLB.** From `startx` to the desktop generated code comes back to Goose
72.1 million times:

| What the return was | Millions | Share |
|---|---:|---:|
| Through a link slot, to an instruction with no kind | 36.0 | 50% |
| Through a link slot, to an instruction with a kind and no block | 10.4 | 14% |
| A way out taken while running, before an instruction of a block | 13.4 | 19% |
| The far way: the page of code is not in the TLB | 5.9 | 8% |
| Through a link slot, to an instruction with no entry, or not yet classified | 3.9 | 5% |
| The far way, the rest (no block there; in the page) | 2.0 | 3% |
| Other ways out | 0.4 | 1% |

- **No kind** (50%), by the first byte, in millions: prefix 66 9.0, F3 (the strings with
  REP) 4.3, XCHG of a byte (86) 3.4, IMUL by a constant (6B, 69) 4.3, prefix 3E 1.7, FE
  1.6, PUSHF 1.3, C7 1.1, SHRD and SHLD 2.4, BT and its group 1.4, C0 0.7. These are P2b,
  P4, P5 and P6, which are left for the 64-bit count.
- **A kind and no block** (14%): a block of one instruction is not made, so one
  translatable instruction between two that are not is the interpreter's. These go when
  their neighbours get kinds, not before.
- **Ways out while running** (19%): asked of the loads among them (MOV, MOVZX, MOV of a
  byte: 8.7 million), all are the TLB not having the page; none is a segment's top, 280
  are an access across two pages. 6.4 million of the 8.7 are user code.
- **The far way** finds no page in the TLB 5.9 million times, and no block where it looks
  only 2 million: prediction (P7) cannot save trips, as the card said, only the host
  instructions of the lookup: 161 million arrivals at 30 each are under 3% of the host's
  instructions for the stretch.

**So the TLB comes before P7.** It has 256 entries for each of the two privilege levels,
found by the page number's low eight bits, shared by code and data, by the interpreter and
the JIT; X with its clients uses more pages than that. A larger one is structure: it is
the same table on x86_64, and the interpreter has it too. It is P9 in `docs/perf.md`, and
P7 is weighed again after it: its ceiling is 3%.

## E090: A larger TLB (2026-11-19)

P9 of `docs/perf.md`.

- **Hypothesis**: The TLB's 256 entries for each privilege level are found by the page
  number's low eight bits, and X with its clients touches more pages than that between
  two changes of CR3: two pages 256 apart push each other out. E089 counted 19.3 million
  returns from generated code that are a page the TLB does not have. **With 1,024 or 4,096
  entries for each level most of those go: generated code is entered under 60 million
  times from `startx` to the desktop (72.1 now), and the host takes at least 5% less
  time; the interpreter without `--jit` is no slower on the boot.** What a larger table
  costs is emptying it (every write of CR3) and walking it (every page of code first
  marked).
- **What changed since last time**: E088 and before took instructions off the general
  path. This is the first change to the memory path since E045; the size becomes a
  constant, and the JIT's loads from the table take it from there.
- **Next move for each result**:
  - A size is at least 3% quicker under X and the boot's interpreter within 1% → keep
    that size; P7 weighed again
  - Trips fall and the time does not → the emptying is what it costs: count CR3 writes
    and marks, and note for x86_64 that the table wants a generation instead of an
    emptying; not kept
  - Trips do not fall → the misses are first touches after CR3 changes, not pages pushing
    each other out; size is not the matter; not kept, and the note for x86_64 is tags
    with an address space number
- **Cut-off**: 8 (now), 10 and 12 bits; the stretch timed three times each, the boot three
  times each without `--jit`.

### Result

2026-11-19. **Kept, by the card's first branch: with 4,096 entries for each privilege level
the host takes 9.23 seconds from `startx` to the desktop (10.52 with 256, in the same
sitting; 12.3% less), and generated code is entered 54.3 million times (72.1).** The
interpreter without `--jit` is 1.4% quicker on the Linux boot (25.91 billion host cycles
against 26.27, medians of three).

| Entries for each level | Stretch, three runs | Median | Entries into generated code | Boot to the prompt |
|---|---|---:|---:|---:|
| 256 | 10.52, 10.37, 10.96 s | 10.52 s | 72.12 million | 2.91 s |
| 1,024 | 9.78, 9.38, 9.91 s | 9.78 s | 61.38 million | 2.66 s |
| 4,096 | 9.23, 9.06, 9.24 s | 9.23 s | 54.29 million | 2.57 s |
| 16,384 | 9.26, 9.43, 9.19 s (a second sitting; 4,096 there: 9.43, 10.04, 10.04) | | 53.99 million | |

16,384 takes away 0.3 million entries more and no time that three runs can show: 4,096 it
is. The emptying at each write of CR3 and the walk at each page of code marked, which the
card feared, do not show at this size. The 17.8 million entries that went are the 19.3
million E089 counted, nearly all.

On E088's 299 million guest instructions a second that is 341 million: over the 305 that
`--speed 4` wants. (The same caution as before: only one sitting's numbers are compared,
and the 299 is itself a ratio put on E087's sitting.)

**What was built.** `TLB_BITS` (`src/state.goose`), 12: every index into the TLB, the
user's half, INVLPG's and the two loops over the whole table take the size from it. The
JIT's code takes the index's width and the half from it, and reaches the three tables
after the first with one more instruction where they are too far for a load's offset
(`a_tlb`). The four tables are 128 KB together (8 KB before).

**Tests.** Five, three of them new files:
- `s_invlpg` and `s_invlpgu` take the page they use from a name; `s_invlpg2` and
  `s_invlpgu2` are the same on 370000h, a page number that does not fit in eight bits.
- `s_tlbcr3`: a page at 370000h read and written, its entry changed and CR3 written,
  twelve times; and code written through 372000h, called, written again and called.
- `s_tlbuser`: ring 0 reads a supervisor's page whose number has bit 8 set; ring 3 then
  reads it from a loop the JIT has translated, and must fault.

Nine wrong builds (INVLPG looking at the old index, or at the old place for the user's
half; a write of CR3 or the marking of a page of code reaching only the first 512
entries; the JIT with the user's half where it was, or reading a page or a tag from the
wrong table), all caught. Three passed at first, and each was the test's fault:
- `s_tlbcr3` summed 11111111h and 22222222h with a rotation between them: a rotation is a
  doubling modulo 2^32 - 1, and a stale read changed the sum by a multiple of that.
- Nothing wrote code through a page above 512.
- `s_tlbuser`'s loop was all short executors, so it was one run of the interpreter and
  the JIT never counted an arrival in it.

**P7 weighed again.** The far way is arrived at 147 million times in the stretch now; at 30
host instructions each that is under 3% of the host's instructions, and a prediction saves
part of it. It is not started: the host keeps up with `--speed 4` by the stretch's
measure, which was the plan's other stopping point.

`tools/difftest.sh` has 163 lines, all ok (the four new self-checks are two lines each).

## E091: 64-bit user-mode instructions against a real CPU, one step at a time (2026-11-19)

The first step of M10 ([roadmap.md](roadmap.md)). rustx86 has no long mode, so there is no
oracle yet for anything 64-bit; this step builds one and the first part of the CPU it is for.

- **Hypothesis**: A static x86_64 ELF with no library, single-stepped under `ptrace` on a
  real x86_64 Linux host, gives a line of registers and flags for each instruction that
  does not depend on the host: with address randomizing off, every register starts at zero
  but RSP, and a test that loads RSP first has the same lines on every run. **A new CPU in
  its own files (sixteen 64-bit registers, REX, RIP-relative addresses, operands of 8, 16,
  32 and 64 bits), run on the same ELF, prints the same lines for the integer instructions
  a compiler emits, undefined flags included, because the flags are taken from the real
  CPU and not from the manual.** Two things single-stepping itself changes are put right in
  the oracle and not in the CPU: the TF bit in what PUSHF pushes and in R11 after SYSCALL.
- **What changed since last time**: every earlier trace was against rustx86 (a 386 and an
  i686). This is a second root file, `src/x64.goose`, beside `src/g86m.goose`: nothing of
  the 32-bit machine is touched, and its suite must stay as it is.
- **Next move for each result**:
  - Traces are the same on two runs of the oracle, and the new CPU matches them on every
    test → the tests and their traces go in; next is SSE2 with sixteen XMM registers by
    the same oracle (E092)
  - The oracle's lines differ between two runs → find what the kernel leaves in a
    register or a flag (the vDSO, AT_RANDOM, the direction the stack grows from) and keep
    it out of the tests, or start the comparison after the tests' first instructions
  - An undefined flag cannot be made to match by a rule on the operands → the test masks
    that flag for that instruction, and the ledger says which and why
- **Cut-off**: the integer instructions of the list in `src/cpu64.goose`'s head; no SSE, no
  x87, no faults delivered (a fault ends the run), three system calls (write, exit,
  exit_group).

### Result

2026-11-19. **Kept, by the card's first branch: ten programs, 27,527 instructions in all,
give the same line of registers and flags after every instruction on the new CPU as on the
real one, and the oracle's two runs of each are the same.** No flag had to be masked: every
undefined flag the tests reach follows a rule on the operands, which is now in
`src/cpu64.goose`.

**What was built.**
- `tools/oracle/step64.c`: forks, turns address randomizing off, runs the program with no
  arguments and no environment under `PTRACE_SINGLESTEP`, and prints RIP, the sixteen
  registers and the flags after each step. Built and run on the host over ssh by
  `ORACLE_HOST=name tools/difftest64.sh`.
- `src/cpu64.goose` (1,027 lines): the CPU. Prefixes and REX, ModRM with SIB and RIP-relative
  addresses, operands of 8, 16, 32 and 64 bits, the instructions listed at its head.
  Products of 128 bits in 32-bit halves and quotients of 128 by 64 bits one bit at a time,
  in Goose; no C.
- `src/x64.goose`: the second root file. Loads a static ELF, answers write, exit and
  exit_group, prints the trace.
- `tools/gen64_tests.py` writes eight of the tests (`tests/asm64/g_*.asm`): cases from a pool
  of edge values and random ones with a fixed seed, nothing checked inside the test. One test
  by hand (`a_first`), and one in C built with gcc on the host and kept built
  (`tests/c64/c_mix`): a CRC, a sort, GCDs, 128-bit products and remainders. The C test ran
  the same as the real CPU the first time it was tried.
- `tools/diff64.py` names the instruction where two traces part and the fields that differ;
  with `all`, every place where they agree on one line and not on the next.

**What the real CPU does that the manual does not say** (an Intel Core i7-3770K, Ivy Bridge;
each is in the code with a comment, and each has a wrong build below):
- **Shifts and rotates: OF is what a count of one would give, at every count.** It is a
  function of the operand (and for RCR of CF, for SHRD of the source's lowest bit), not of
  the result. The 32-bit CPU here follows a 386, which leaves OF alone for right shifts
  unless the count is one. Found by tabulating, for each instruction and form, which of six
  candidate rules agreed with all 46 cases: none did until this one.
- **The one exception: ROL and ROR of a register by a constant over one leave OF as it was.**
  By CL, or of memory by a constant, they follow the rule above. (Two forms of one
  instruction that differ in a flag: the trace is of what this CPU's own decoding does.)
- RCL and RCR by a whole turn (9 for a byte, 17 for a word) change nothing, flags included.
- The shifts clear AF; the rotates leave it. MUL and IMUL set SF and PF from the lower half
  and clear ZF and AF.
- BSF and BSR of zero leave the whole destination, upper half included, even with a 32-bit
  operand; a CMOVcc with a 32-bit operand clears the upper half even when it does not move.
- **Between two repetitions of REPE or REPNE CMPS and SCAS, the flags are still those the
  instruction began with**: the comparison's flags appear only when the repetition ends. RF
  is set in between, as the manual says.

**What single-stepping changes, put right in the oracle.** Three, where the card expected
two: TF in the word PUSHF pushes, TF in R11 after SYSCALL, and TF in the flags the kernel
reports for the instruction after a POPF (it hides the bit otherwise; after POPF it takes the
program to have set it). TF is never printed.

**Wrong builds.** 38, each one change to `src/cpu64.goose` (`build/mut91.py`): REX's three
bits, the SIB byte's special base, RIP-relative with a constant behind, 32-bit addresses,
the cleared upper half, the high byte registers, carry and borrow at 64 bits, each rule
above, the 128-bit multiply and divide, the bit tests' far offsets, POP to an address made
from RSP, POPF's mask, the strings, LOOP, RET with a constant, and others. 37 were caught at
once; the 38th (a CMOVcc that does not move, leaving the upper half) passed because no test
had anything in the upper half, a case was added to `g_cond`, and it is caught.

**Rejected on the way.**
- The first parity table, typed in again instead of taken from `src/alu.goose`, had two
  wrong rows: 30 differences in `g_alu`, all PF. The table is now the 32-bit one's, copied.
- OF "by the formula on the result at every count" (the first version), then "unchanged
  unless the count is one" for the rotates (right for one form of two).
- A test that read through `[r12 + r12]`, an address outside the program: the real CPU
  ended it with a signal, and the oracle's trace stopped there, which is how it was seen.

**Not done, and next.** No SSE and no x87: E092 is SSE2 with sixteen XMM registers by this
oracle, the x86_64 ABI's floating point being all SSE. No faults are delivered. Speed was
not looked at: the CPU decodes every instruction every time, into globals. The 32-bit
machine's sources are untouched, and its suite is as it was (163 lines ok).

## E092: the same tests under QEMU's user-mode emulator (2026-11-19)

After E091 the owner asked whether a Docker backend made of this CPU (M11 of
[roadmap.md](roadmap.md)) could draw interest beside QEMU, FEX-Emu, Box64 and Blink. One
thing this project has that could: tests whose expected results are a real CPU's, step by
step. This runs them on the emulator Docker uses by default. (E091 called SSE2 "E092"; SSE2
is the entry after this one.)

- **Hypothesis**: QEMU's user-mode emulator (10.2.1, `-cpu IvyBridge`, one instruction per
  translation block, logging the CPU state) gives the same registers after every
  instruction of E091's ten programs as the real CPU, and the same flags wherever the
  manual defines them. **Where it differs, the difference is a flag the manual leaves
  undefined, or the way a REP instruction is stepped; none is a wrong register or a wrong
  defined flag.**
- **What changed since last time**: E091 compared this project's CPU with the real one.
  The emulator under test is another's, and nothing of this project's code is changed.
- **Next move for each result**:
  - A register or a defined flag differs → look until it is certain which side is right by
    the manual; if QEMU is wrong, write the smallest program that shows it and put the
    draft of a report in front of the owner (nothing is sent without a go-ahead); the test
    suite as a thing others can use becomes a named part of M11
  - Only undefined flags differ → a table of which and how, for the write-up; the suite is
    this project's own tool and not a finding about others; M11's case rests on being
    small and readable
  - QEMU cannot be made to print a state after each instruction that lines up with the
    oracle's → step it through its gdb stub instead, once; if that fails too, compare what
    the programs print and the registers at the end only
- **Cut-off**: the ten programs of E091, QEMU only. Blink and FEX-Emu are not tried here.

### Result

2026-11-19. **By the card's first branch, in part: one difference is a wrong register, and
QEMU is the side that is wrong; but it was already found and fixed upstream. Everything
else is as the hypothesis said.** Of 27,527 instructions QEMU 10.2.1 (Ubuntu's package,
unpacked without installing) gives the same registers and flags as the real CPU after
26,876 of the states it logs; 555 fields differ, each counted once, at the instruction
that brings the difference (`tools/qemu64.py`):

| What | Where | Count | Kind |
|---|---|---:|---|
| **RCL and RCR by a constant that is a whole turn (9 for a byte, 17 for a word; 18 too): QEMU leaves 0 in the operand and clears CF. The real CPU, the manual and this project's CPU change nothing** | `g_shift` | 5, in 3 instructions | **a bug in QEMU** |
| OF after shifts and rotates by a count over one | `g_shift`, `c_mix` | 450 | undefined |
| ZF after MUL and IMUL (the real CPU clears it; QEMU sets it from the result) | `g_muldiv` | 33 | undefined |
| SF and PF after BSF and BSR (and TZCNT, LZCNT, which this CPU model runs as those) | `g_bits` | 49 | undefined |
| BSF and BSR of zero with a 32-bit operand: the real CPU leaves the upper half, QEMU clears it | `g_bits` | 7 | undefined (the manual says the destination is) |
| RCX and R11 after SYSCALL: the kernel leaves the return address and the flags there; QEMU's user mode leaves them as they were | `a_first`, `c_mix` | 11 | not the CPU: the kernel's ABI says only that they are lost |

`g_alu`, `g_cond`, `g_mov`, `g_stack` and `g_string` are the same throughout (the oracle's
lines between two repetitions of a REP instruction have no counterpart in QEMU's log and
are passed over).

**The bug.** A program of eleven cases (`build/t64/rclq.asm`, not kept: `g_shift` has the
cases) run freely, not stepped: `rcl al, 9`, `rcl ax, 17`, `rcr al, 9`, `rcr ax, 17` and
`rcl al, 18` give 0 with CF clear under QEMU, with `-cpu IvyBridge` and with the default
model; by CL the same counts are right. It is QEMU's work item 3452 ("Incorrect TCG
translation of rcr instruction", May 2026): the count is reduced modulo 9 after the test
for a zero count has been decided, and the code for a nonzero count runs with a count of
zero. Fixed upstream ("apply mod to immediate count of an RCL/RCR operation") and in the
stable series from 10.2.4; the package tried here is 10.2.1. **So there is nothing to
report; what it shows is that these tests, written with no knowledge of that bug, met it
in the first run.** The fix carries a question in a comment, whether the flags should
change when the count is not zero but a whole turn. On an Ivy Bridge they do not: OF and
CF are as they were (`g_shift`'s four cases). Saying so upstream would be a message to the
outside, and is the owner's to decide.

**What it means for M11.** The suite is worth something to others, not only to this
project: it is the first branch of the card. It becomes a named part of M11
([roadmap.md](roadmap.md)): the oracle and the generated tests kept able to run against
any user-mode emulator, with a table like the one above for each. Blink and FEX-Emu were
not tried (the card's cut-off).

**Rejected on the way.** The first count had 1,988 differences: a flag that differs stays
different until the next instruction that sets it, and each line was counted. The comparer
now shows only what an instruction brings.

## E093: SSE and SSE2 on the 64-bit CPU, against the real one (2026-11-19)

The second step of M10, and what M11 needs too: the x86_64 ABI passes and returns floating
point in XMM registers, and every C library copies memory through them.

- **Hypothesis**: The oracle of E091, made to print the XMM registers and MXCSR as well,
  gives lines that are the same on two runs. **The packed-integer and floating-point
  helpers of the 32-bit machine's `src/sse.goose` (E077, written against rustx86 and never
  against a real CPU), moved to a file both CPUs share (`src/lanes.goose`) and used with sixteen XMM registers
  and the 64-bit forms, give the real CPU's XMM registers, general registers and flags
  after every instruction of generated tests and of a C program that computes in doubles
  and singles.** MXCSR's six status bits are left out of the comparison on both sides:
  floats here are the host's, and nothing says after an operation whether it was exact.
- **What changed since last time**: E091 had no XMM register in its trace and no opcode
  of these. E077's SSE2 was compared with rustx86 only; this is its first comparison with
  hardware. The shared file changes which file the 32-bit machine's helpers are in, and
  nothing else of it.
- **Next move for each result**:
  - Everything matches → the tests and traces go in; next is the choice between M11's
    first step (system calls passed to a Linux host) and M10's long mode
  - A helper from E077 is wrong against the real CPU → it is wrong on the 32-bit machine
    too: fix it in the shared file, and say so in the ledger with the case
  - A result depends on something the host's floats do not give (a NaN's payload, a
    denormal, the rounding mode in arithmetic) → written by hand for that case if a
    compiler's code can meet it; else the tests leave it out and the ledger says what is
    not modelled
  - The 32-bit suite or its layout check changes with the shared file → the helpers are
    copied instead of shared, and the 32-bit sources go back to what they were
- **Cut-off**: SSE and SSE2 as compilers and C libraries use them. No MMX registers on the
  64-bit CPU, no SSE3 or later, no x87. The reciprocal approximations (RCPPS, RSQRTPS) are
  not compared: the chip's are approximate by a table.

### Result

2026-11-19. **Kept, by the card's first branch: four programs, 10,031 instructions, give the
real CPU's general registers, flags, XMM registers and MXCSR (without its status bits) after
every instruction, and the oracle's two runs of each are the same. The three generated
tests and the C program all matched the first time each was run: no helper from E077 was
wrong against the real CPU.** With E091's ten the 64-bit suite is fourteen programs and
37,558 instructions. The 32-bit suite is as it was with the helpers in the shared file,
and its layout check passes.

**What was built.**
- `src/lanes.goose`: what MMX and SSE2 compute, apart from any CPU (the packed integers
  lane by lane, shifts, unpacking, packing, shuffling, floats with the chip's rules for
  NaNs), moved out of `src/sse.goose` with the declarations of `rint` and the four
  bit-conversions they need. No global in it. (The file's first name, `simd`, is a word
  Goose keeps for itself.)
- `src/sse64.goose` (442 lines): the 64-bit CPU's operands around them. XMM8 to XMM15 by
  REX, the 64-bit forms (MOVQ with a general register, CVTSI2SS and SD from 64 bits, the
  conversions to 64 bits, MOVNTI), MASKMOVDQU. No MMX register: those forms stop the run.
- New against E077: **MXCSR's rounding mode is obeyed where a float becomes an integer**
  (to nearest, down, up, toward zero), and **a 64-bit integer becomes a single with one
  rounding**: by way of a double it would be rounded twice, so the integer is cut to 53
  bits with one more bit saying whether anything was lost.
- The oracle's `-x` and `x64 --trace-xmm`: a line gains MXCSR and each XMM register when
  it is not what it was on the line before, so the traces stay small (115 KB for the four).
- Tests: `x_move`, `x_int`, `x_float` from the generator, with 128-bit constants in a
  table after the code and pools of edge lanes and of floats (zeros of both signs,
  infinities, denormals, quiet and signalling NaNs with payloads, the numbers around
  2^31, 2^53 and 2^63); `tests/c64/cx_float` in C: a square root by Newton's method, a
  polynomial, a dot product of singles, a structure of doubles passed and returned by
  value, conversions each way, and structure and block copies.

**Wrong builds.** 47, in `src/sse64.goose` and `src/lanes.goose` (`build/mut93.py`). 42
caught at once. Three passed and each got cases: the smaller and the larger of equal
operands (the two zeros: the second operand comes out), a predicate that is true of a NaN,
and an integer whose lowest bit alone decides which way its single rounds. Two are not
wrong builds at all: reading 64 bits of memory where 32 are used, and `>` for `>=` at
2^31, where the indefinite integer and the number have the same bits.

**Not modelled, and not in the tests.**
- MXCSR's six status bits (was the result exact, did it underflow, was an operand
  invalid): left out of the trace on both sides, as the card said. A program that reads
  them (`fetestexcept`) gets what it last wrote.
- MXCSR's rounding mode in arithmetic: add, subtract, multiply, divide and the square root
  round to nearest whatever it says. The conversions obey it.
- The masks: with an exception unmasked the real CPU would fault. Nothing faults here.
- RCPPS, RCPSS, RSQRTPS, RSQRTSS are exact here and approximate on the chip.
- Denormals-are-zero and flush-to-zero.
- An aligned move of unaligned memory, which faults on the real CPU.

**Next.** By the card: the choice between M11's first step and M10's long mode, which is
the owner's.

## E094: long mode's system side: paging and faults, against the real CPU under KVM (2026-11-19)

The owner chose M10's kernel half before M11. This is its first step. The whole of it, in
the order planned ([roadmap.md](roadmap.md)): paging and faults at privilege level 0
(this entry); privilege level 3, the TSS's stacks, SYSCALL and SYSRET, interrupts from
outside; the devices of the 32-bit machine put behind the 64-bit CPU; the kernel.

- **Hypothesis**: The roadmap named QEMU's own emulation as the oracle for system
  instructions. The Linux host has QEMU with KVM, where the guest's instructions run on
  the real CPU: a better oracle, and the one used. A test is a small image that QEMU loads
  by the multiboot protocol; its 32-bit beginning turns long mode on and jumps to 64-bit
  code, and this project's loader, which has no 32-bit CPU to run that beginning, sets the
  state it leaves and starts at the 64-bit code. The test prints what it finds on the
  serial port and stops through a port. **With control registers, four-level paging (4 KB
  and 2 MB pages, the present, write, user and no-execute bits, CR0.WP, accessed and dirty
  bits), faults delivered through a 64-bit IDT (error code, CR2, the frame pushed, the
  IST), IRETQ, and the instructions that load the tables, the 64-bit CPU prints the same
  text as the real CPU under KVM for every test.**
- **What changed since last time**: E091 and E093 ran programs in user mode with memory
  as one block, compared line by line under ptrace. Here the CPU has privilege level 0,
  memory goes through page tables, a fault is delivered and not the end of the run, and
  what is compared is what the test prints, since nothing steps a guest under KVM as
  cheaply as ptrace steps a process.
- **Next move for each result**:
  - Every test prints the same → the tests and their expected text go in; next is
    privilege level 3 and interrupts (E095)
  - The image does not start under KVM, or prints differently on two runs → fall back to
    QEMU's own emulation for that test and say so; if neither starts it, the way in is
    wrong: read what multiboot leaves and fix the frame before any CPU code
  - A printed value differs and the manual does not settle it → what the real CPU does is
    taken, as in E091, with a comment
  - A fault's frame cannot be made right without restoring registers the instruction had
    changed → every instruction's start is saved (seventeen words copied), and its cost
    is written down for the speed work
- **Cut-off**: privilege level 0 only; no TLB in the emulator (every access walks the
  tables: slow, and the tests invalidate as a real CPU needs, so that a TLB can be added
  under them); no devices but a port to print to and a port to stop by.

### Result

2026-11-19. **Kept, by the card's first branch: three tests print the same text on the
64-bit CPU as on the real CPU under KVM, 197 lines, and KVM's two runs of each are the
same.** `y_first` matched before any system code was written beyond the loader, `y_fault`
(101 lines) the first time it was run, and `y_paging` (87 lines) after one fix.

**What was built.**
- `tests/sys64/sys.inc`: the frame the card describes. QEMU enters by multiboot and the
  image's 32-bit beginning turns long mode on; `x64` sees the "G64T" header and sets the
  same state. It started under KVM and under QEMU's own emulation at the first try.
  `tests/sys64/idt.inc`: an IDT whose gates all reach one handler, which writes down the
  vector, the error code, the frame, CR2 and its own flags, and returns to where it came
  from or to a place the test names; a hook lets a test put right what faulted.
- `tools/systest64.sh`: builds the tests, compares what they print with
  `tests/expected64/y_*.out`; with `ORACLE_HOST`, takes that text again under KVM, twice,
  and once under QEMU without KVM, naming a test that prints differently there.
- `src/sys64.goose` (426 lines): control registers, EFER and the MSRs of SYSCALL and of
  the FS and GS bases; `xlate`, the walk of four levels; `fault` and `deliver`; LGDT,
  LIDT, SGDT, SIDT, LTR, STR, LLDT, SLDT, SMSW, INVLPG, CLTS; IRETQ and the far return.
  In `src/cpu64.goose`: MOV to and from segment and control registers, PUSH and POP of FS
  and GS, RDMSR and WRMSR, IN and OUT, HLT, CLI and STI, INT and INT3, UD2 and the divide
  error as faults. `src/x64.goose`: the loader, and two ports (the serial port's data and
  status, and the port that stops the machine).
- **Every instruction's start is saved** (sixteen registers, the flags, the privilege
  level), by the card's last branch: a POP to memory that is not there must leave RSP as
  it was, and `y_fault` has that case. It is a copy of 137 bytes on every instruction, and
  the first byte's page is walked once more to see that it may be executed: both are for
  the speed work, with the TLB.

**What the real CPU does, taken as found.**
- The flags pushed with a fault have RF set (a divide error, an undefined opcode, a page
  fault, a protection fault); those pushed by INT and INT3 do not.
- A write that lies across two pages, the second of which is not there, writes nothing,
  and CR2 is the second page's first byte. (The first version walked to the access's last
  byte: CR2 came out three too high. The one fix.)
- A write that is refused sets no accessed bit on a page nothing else has touched.
- Bit 63 of an entry while EFER.NXE is clear is a fault with error code 9: "there", and a
  reserved bit.
- LTR marks the TSS's descriptor busy; a gate's stack from the TSS is aligned to sixteen
  like any other.

**Where QEMU's own emulation prints differently from the real CPU** (10.2.1; found
because the script runs both; none is reported, each is one line of a table for later):
- RDMSR of an MSR that does not exist: no fault (the real CPU: #GP).
- WRMSR to EFER with a reserved bit set: no fault (the real CPU: #GP).
- The reserved-bit page fault's error code: 8 (the real CPU: 9).

**Wrong builds.** 49, in `src/sys64.goose` and `src/cpu64.goose` (`build/mut94.py`). 39
caught at once. Nine passed and got cases or a better test: bit 63 without NXE, the
accessed bit after a refused write, a vector past the IDT's end where what lies there
looks like a good gate, a handler above 4 GB (the gate's upper half), IRETQ giving back
IF and IOPL, a TSS above 16 MB (the descriptor's upper parts), LTR's busy mark, and MOV
from a segment register to a register and to memory. One is not caught and cannot be by
these tests: RF left set on the way into a handler, which PUSHF does not show; it would
take a fault inside a handler to see it.

**Not done, and next.** No privilege level 3, no SYSCALL, no interrupt from outside, no
TLB, no devices: E095 and after, as the card's first paragraph says. The 32-bit machine's
sources are untouched in this entry; the 64-bit user-mode suite is as it was (14 ok).

## E095: privilege level 3, SYSCALL and SYSRET, against the real CPU under KVM (2026-11-19)

The second step of M10's kernel half.

- **Hypothesis**: With a return to privilege level 3 by IRETQ and by SYSRET, the way back
  by SYSCALL (STAR, LSTAR, FMASK), by INT through a gate that allows it and by a fault (the
  stack from the TSS, SS made null), SWAPGS, and the checks that level 3 meets (privileged
  instructions, IOPL for CLI, STI, IN and OUT, the user bit of a page, a gate's privilege
  level, IRETQ to a more privileged level), **a test that goes to level 3 and back some
  dozens of times prints the same on the 64-bit CPU as on the real CPU under KVM**: the
  selectors and flags seen at level 3, what SYSCALL leaves in RCX and R11, every fault's
  vector, error code and frame.
- **What changed since last time**: E094 never left privilege level 0; `deliver` read the
  TSS's stack for a more privileged handler and IRETQ took a privilege level from the
  frame, and neither had run. One thing is taken out of this step that the plan had in it:
  **interrupts from outside**. They need a device to come from; they go with the devices,
  two steps on, where HLT also gets something to wake it.
- **Next move for each result**:
  - The test prints the same → it goes in; next is the TLB under the walk (E096)
  - A selector, a base or a flag at level 3 differs and the manual leaves it open (what
    IRETQ does to DS, ES, FS and GS that level 3 may not use; FS's base after that) → what
    the real CPU does is taken, with a comment
  - SYSRET with an address that is not canonical does not fault on the real CPU the way
    Intel's manual says (in privilege level 0, after nothing has changed) → the test keeps
    the case and the code follows the real CPU
- **Cut-off**: 64-bit code at level 3 only (no compatibility mode: SYSRET without REX.W
  and a 32-bit code segment stop the run); a far return to level 3 is not written (IRETQ
  and SYSRET are what a 64-bit kernel uses).

### Result

2026-11-19. **Kept, by the card's first branch: `y_user`, 404 lines, prints the same on the
64-bit CPU as on the real CPU under KVM; the other three system tests still do.** It goes
to privilege level 3 eleven times and takes 42 faults and traps on the way.

**What was built.** In `src/sys64.goose`: SYSCALL and SYSRET, SWAPGS, IRETQ to an outer
level (the data segment registers that level may not use are made null), DR6 and DR7 as
places that keep what is written, and the single step. `deliver` and `xlate` had the rest
since E094, unrun: the stack from the TSS, SS made null, the user bit of a page, the gate's
privilege level. All of it ran the first time except what follows.

**Not in the card: the single step.** The test's first version gave SYSRET a set of flags
with TF in it, by carelessness; the real CPU answered with seven traps through vector 1
and the emulator with none. TF is what a debugger in the guest steps a program with, so it
is written and the test now sets it on purpose, three ways. What the real CPU does, which
took two tries to get right:
- **Vector 1 follows an instruction that began with TF set.** So the instruction after a
  POPF or an IRETQ that sets TF is the first to be followed by one (not the POPF itself),
  and a POPF that clears TF still is followed by one. This is what the manual says.
- **SYSCALL and SYSRET go by TF as they leave it.** SYSRET with TF in R11 is followed by
  a trap at once, before the first instruction at level 3; SYSCALL with TF in FMASK is
  followed by none, though it began with TF set. (The first version went by TF afterwards
  for everything, the second by TF before for everything; each was right for half.)
- An instruction that itself goes to a handler (INT, a fault) is followed by none. The
  flags pushed with the trap have TF and not RF.

**What else the real CPU does, taken as found.**
- IRETQ to level 3 makes DS, ES, FS and GS null when their descriptor is level 0's, and
  leaves one whose descriptor is level 3's. FS's base is not touched by that.
- SYSRET takes from R11 every flag but RF and VM (3C7FD7h), IOPL and the two
  virtual-interrupt bits included; POPF at level 0 then leaves those two as they are, and
  IRETQ at level 0 loads them from its frame.
- SYSRET to an address that is not canonical faults at level 0, on the stack it was run
  with, as Intel's manual says.
- At level 3, POPF and IRETQ that would turn IF on, or change IOPL, leave them and say
  nothing; SGDT, SIDT, STR and SMSW are allowed and give the real values.

**Wrong builds.** 41 (`build/mut95.py`). 36 caught at once; four got cases (a segment
register level 3 may use is not made null; IRETQ at level 3 cannot set IF; SS is null in
a handler reached from level 3; the IDT and the TSS in pages level 3 may not use, which
the CPU reads as itself). One changes nothing.

**QEMU's own emulation** does not finish this test: after SYSCALL its flags are 2 where
the real CPU's are 896h, and nothing is printed after the SYSRET. Not looked into.

**Not done, and next.** Interrupts from outside (with the devices, as the card says),
compatibility mode, the far return to level 3. Next by the card: the TLB (E096).

## E096: a TLB under the 64-bit CPU's page walk (2026-11-19)

The third step of M10's kernel half.

- **Hypothesis**: Every access of the machine walks four levels of tables (E094), and
  every instruction walks once more for its first byte. **Six tables of 4,096 entries
  (read, write and execute, each for privilege level 3 and for the rest), found by the
  page number's low twelve bits, where an entry is made only by a walk that succeeded and
  so stands for "this access is allowed and its accessed and dirty bits are set", emptied
  by a write of CR3, CR0, CR4 or EFER and one page at a time by INVLPG, take the walk off
  all but the first access of a page: a loop of plain instructions over memory runs at
  least three times as fast, and the four system tests print what they printed.** What a
  guest can see of a TLB is what it may not do: use a translation the guest has
  invalidated, let level 3 use what level 0 walked, write through an entry made by a
  read without setting the dirty bit, keep allowing what CR0.WP or EFER.NXE has since
  forbidden. A new test asks each of those of the real CPU and of this one.
- **What changed since last time**: E094 and E095 had no TLB by intent, and their tests
  invalidate as a real CPU needs. The 32-bit machine's TLB (E045, E090) is the model: four
  tables there, no execute table.
- **Next move for each result**:
  - Three times as fast or more and all five tests the same → kept; next is the devices
    (E097)
  - The tests are the same and the loop is under twice as fast → the walk was not what
    the time went on: count where it does go (the save of sixteen registers at each
    instruction is the first suspect) before keeping anything
  - A test differs → the table that let it through is missing a key (the privilege
    level, the kind of access) or an emptying; a wrong build for that case goes in with
    the fix
- **Cut-off**: no global pages kept across a write of CR3 (everything is emptied: slower
  and never wrong), no address-space numbers (CR4.PCIDE is not offered), no fast path in
  front of the tables. The loop is a measure of this CPU against itself, not of anything
  a kernel does.

### Result

2026-11-19. **Kept, though the hypothesis's number was missed by a little: the loop takes
1.83 seconds where it took 5.34 (medians of three; 2.9 times as fast, and the card said
three), and the five system tests print the same as the real CPU under KVM.** The card
named what to do at three times and at under two, and nothing between: 2.9 is taken as
the first, with what the rest of the time goes on counted as the second asks.

| Build | The loop, three runs | Instructions a second |
|---|---|---:|
| Before (a walk for every access and one more for every instruction) | 5.91, 5.41, 5.34 s | 11.8 million |
| With the TLB | 1.84, 1.84, 1.83 s | 34.4 million |
| The same without the save of sixteen registers at each instruction (a counting build) | 2.29, 1.84, 1.78 s | 3% fewer seconds |
| and without the check of the first byte's page (which then went anyway: see below) | 2.00, 1.80 s | 2% fewer again |

The loop is 63 million instructions and prints the same sum on the real CPU. **The walk
was two thirds of the time and is gone; the save at each instruction, which E094 wrote
down as a cost, is 3%.** What is left is the interpreter itself, which decodes every
instruction into globals every time: the 32-bit machine was there before its decode cache
(E010 on). That is for after the kernel boots, by a count of what the kernel runs.

**What was built.** `xlate` in `src/sys64.goose` looks in one of six tables and calls
`walk` on a miss; `walk` fills the table when it succeeds. Emptied by writes of CR3, CR0,
CR4 and EFER. INVLPG drops every entry in the address's 2 MB, since an entry stands for
4 KB and a 2 MB page's entries may be anywhere in it; if an entry of a 1 GB page was made
since the last emptying, everything.

**Two things the wrong builds changed in the design.**
- **Instructions are fetched through the execute table.** They were read like data, with
  one separate check that the first byte's page may be executed. A wrong build that left
  the execute tables out of the emptying passed: the stale entry was only ever asked
  "may this be executed", and the bytes came through the read table. Now every fetched
  byte goes through the execute translation, the separate check is gone, and an
  instruction that runs on into a page that may not be executed faults there.
- **INVLPG had a quick path for when no 2 MB page was about, and it never ran**: the
  tests' own code is in 2 MB pages, as a kernel's is. Two wrong builds of it passed. The
  path is taken out.

**The test** (`tests/sys64/y_tlb.asm`, 59 lines of output): a write after a read sets the
dirty bit; level 3 after level 0 on level 0's page; level 3 writing after reading where it
may only read; executing after reading where it may not; the same after the right is
taken away; CR0.WP turned on after a write it would have refused; EFER.NXE turned off
after a read through an entry with bit 63; one page invalidated and then read, written
and executed; a write of CR3; three pages that share a place in the tables (two of them
4,096 pages apart, the third 65,536); a 2 MB page invalidated by one address in it and
read at another; level 3 reading the IDT's page after a fault has had the CPU read it.

**Wrong builds.** 17 (`build/mut96.py`). 15 caught, seven of them after the changes above
and three new cases. Two change no result: no emptying at a write of CR4 (no bit of CR4
that this CPU offers changes a translation), and filling only the read tables (every
write and fetch then walks: slow, and right).

**Rejected on the way.** The test read through a register the mapping macro had changed,
and so read address 3: the real CPU printed what a BIOS leaves there, the emulator zero.
The test was wrong; and nothing here may read memory it has not written.

**Next.** The devices (E097): the interrupt controller, the timer and the serial port of
the 32-bit machine behind the 64-bit CPU, interrupts from outside, a HLT that wakes.

## E097: the 32-bit machine's devices behind the 64-bit CPU; interrupts from outside (2026-11-19)

The fourth step of M10's kernel half, and the test of what the roadmap has said since M6:
"the devices carry over".

- **Hypothesis**: `src/dev.goose` (the two interrupt controllers, the timer, the serial
  port, the keyboard controller, the clock, the IDE disk, PCI and the network card) knows
  the CPU it serves only by one line, `import state`, and by the virtual time it reads:
  it reads no register and no memory. **With that line gone the file is in both programs
  unchanged otherwise; the 32-bit machine's suite and layout check are as they were; and
  the 64-bit CPU, given the same file, a virtual time, interrupts taken between
  instructions when IF allows (not in the instruction after STI), and a HLT that waits
  for one, prints the same as the real CPU under KVM in a test that counts timer
  interrupts, takes one at privilege level 3, holds one while IF is clear, and takes the
  serial port's and the timer's in the order of their lines.**
- **What changed since last time**: the 64-bit machine had two ports, both in `x64.goose`,
  and HLT ended the run. E095 left interrupts from outside for this step.
- **Next move for each result**:
  - The file is shared, both suites pass, the test prints the same → kept; next is the
    x87 and FXSAVE (E098)
  - The 32-bit suite or its layout check changes with the one line gone → the devices
    are split from what is the 32-bit machine's own in that file, in a way that leaves
    its globals where they are; if that cannot be done without moving them, a copy for
    the 64-bit CPU and a note of what is doubled
  - The test differs in something that depends on how long things take (how many
    instructions a tick is, when the serial port's interrupt comes) → that is not the
    CPU's and not compared: the test is changed to print only what does not depend on it
  - The test differs in the order or the frame of an interrupt → the CPU's side is
    wrong: fix, with a wrong build
- **Cut-off**: the interrupt controllers, the timer and the serial port are what the test
  uses; the rest of the file comes along untested here. No local APIC (CPUID does not
  offer one; the kernel then uses the 8259s).

### Result

2026-11-19. **Kept, by the card's first branch: `src/dev.goose` is in both programs with
one line taken out and nothing else changed; the 32-bit suite is 163 lines ok and its
layout check passes; and `y_irq`, 27 lines, prints the same on the 64-bit CPU as on the
real CPU under KVM, with the five earlier system tests.** "The devices carry over" was
true to the letter: the file read no register and no memory of the CPU it served.

**What was built.**
- `src/dev.goose`: `import state;` removed. The names it uses from outside are two, the
  virtual time and the table of ports nothing answers, and each program has its own.
- `src/x64.goose`: `between()`, what the machine does between two instructions: the
  timer's tick when its time has come, sleep while halted (virtual time goes straight to
  the next tick; with IF clear or no timer running, nothing can wake it and the run ends
  saying so), and a request from the interrupt controller taken when IF is set, no fault
  is waiting, and the instruction just done was not an STI that set IF. It is delivered as
  a trap: the next instruction's address, no RF. The run loop calls it only when the
  timer is due, the machine is halted or a request is waiting. `io_in` and `io_out` go to
  the devices' ports at 8, 16 and 32 bits; port F4h still stops the machine.
- `src/x64.build`: the two C files the devices need (the disk, the network).
- Tests: `y_irq`; `tests/sys64/ring3.inc`, the visit to level 3 that `y_tlb` had, shared;
  sixteen more stubs in `idt.inc` for the controllers' vectors.

**The loop of E096** takes 1.93 seconds with the devices in (1.83 before): the store of
the virtual time and the test at each instruction, 5%.

**What depended on how long things take, and was taken out of the test** (the card's third
branch, three times):
- With the first interrupt not yet answered, the test waited for the controller to show
  a second request. Under KVM it waited for ever: KVM's timer does not send a tick while
  the one before is unanswered. Here the controller keeps the second. That is the timer's
  model, not the CPU's; the test now watches the timer's counter go round twice instead,
  and both agree that no second interrupt arrives.
- After the answer, a HLT waited one tick longer here than there, for the same reason;
  the test spins there instead.
- A count of every handler entry at the end was dropped.

**Two faults of the tools, both found by reading the output and not by a failing
comparison.**
- **`tools/systest64.sh` took a test that never finished for its expected text.** The run
  under KVM hung, was cut off at thirty seconds twice, and the two cut-off outputs were
  the same. The script now also wants QEMU's status to be the one the test's own EXIT
  gives.
- **The wrong-build runs had a limit of three million instructions, and `y_irq` sleeps
  past that** (a tick is 763,648 instructions here): every wrong build "was caught", by
  not finishing. Seen because wrong builds that could not matter were caught too. The
  limit is three hundred million.
- And the test's last part printed that no interrupt came, on both CPUs: coming back
  from level 3 had taken the handler's hook away. A test that agrees with the real CPU
  can still be testing nothing.

**Wrong builds.** 11 (`build/mut97.py`). Seven caught, one of them after a case was added
(one HLT ends with one interrupt). Four are not, and are named: an STI shadow even when
IF was already set (nothing can be made to depend on it); waking from HLT with IF clear
(the real CPU would sleep for ever, so there is nothing to compare); and 16-bit and 32-bit
port access, which no device this test uses needs. The last two are for the disk's and
PCI's tests.

**Not done, and next.** The devices beyond the three are untested behind this CPU. No
local APIC. Next: the x87 and FXSAVE (E098), then the kernel.

## E098: the x87 on the 64-bit CPU, and FXSAVE (2026-11-19)

The fifth step of M10's kernel half. The owner chose it before the kernel is tried: a
64-bit kernel saves and restores the floating-point state with FXSAVE at every switch
between programs, and `long double` in a C library is the x87's 80 bits.

- **Hypothesis**: `src/fpu.goose` (E013 to E016, for the i686; never compared with a real
  CPU, only with rustx86 and by what C libraries print) touches the CPU it serves in a
  dozen places: the memory operand, three flags, AX, the size of the environment, and two
  ways of stopping. **With those behind a few functions that each CPU gives, the file is
  in both programs; the 32-bit suite and its layout check are as they were; and on the
  64-bit CPU, under the ptrace oracle of E091, loads and stores of every width, the four
  operations at each precision and rounding of the control word, comparisons, the
  conversions to integers, and FXSAVE and FXRSTOR in their 64-bit layout give the real
  CPU's registers and memory after every instruction.**
- **What changed since last time**: E093 did the same for SSE2 and found nothing wrong in
  the shared code. The x87 has more that the host's doubles cannot give: 64 bits of
  mantissa, and constants and a square root to that precision.
- **Next move for each result**:
  - Everything compared matches → kept; next is the kernel (E099)
  - A result's last bits differ where the file computes in doubles (the square root, the
    constants, FSCALE, FPREM) → done in integers at 64 bits if a C library's `long double`
    code can meet it; else out of the comparison, and the ledger says so
  - The status word's exception bits make a trace differ (the file never sets them) → the
    tests clear them before reading the status word, and that is said; they are not
    modelled
  - A helper is wrong against the real CPU → wrong on the 32-bit machine too: fixed for
    both, with the case
  - The 32-bit suite or layout changes with the file shared → a copy for the 64-bit CPU
    instead, as E097's card had it
- **Cut-off**: no floating-point exception is delivered (as on the 32-bit machine). The
  functions that go through the host's library (FSIN, FCOS, FPTAN, FPATAN, F2XM1, FYL2X,
  FYL2XP1) are not compared: the chip's last bits are its own. FXSAVE's record of the last
  instruction's address is not kept.

### Result

2026-11-19. **Kept, by the card's first branch, after the fourth: `src/fpu.goose` is in both
programs behind seven names; on the 64-bit CPU four new programs (the generated `f_x87`,
5,298 instructions; `x_fxsave`; `c_ld` in C with `long double`; and the system test
`y_fpu`) give the real CPU's registers and memory, or print what it prints. But the file
was not right against the real CPU as it stood: 50 of `f_x87`'s first 4,663 lines differed,
from nine causes, and all nine were wrong on the 32-bit machine too. They are fixed for
both.** E093 found nothing wrong in the shared SSE code; here the oracle earned its keep.

**What the real CPU does that the file did not** (each fixed in `src/fpu.goose` unless
said, each with a wrong build):
1. **FCOMI and its kin clear OF, SF and AF** as well as setting ZF, PF and CF. (In the
   two CPUs' `fp_set_zpc`.)
2. **A comparison clears C1.**
3. **A NaN loaded from a single or a double comes in quiet.**
4. **A result that is not a number, of operands that were** (infinity less infinity, zero
   by zero), **is the indefinite: quiet, sign set.** The host's own is positive.
5. **An empty register reads as the indefinite** (the masked answer to a stack fault).
   The saves (FNSAVE, FXSAVE) still write what is in it: `raw80`.
6. **A store to a single or a double rounds once, from all 64 bits, as the control word
   says.** It went by way of the register's double: twice for a single, and to nearest
   whatever the rounding. `store_float`, with the cases a double-then-single path gets
   wrong: ties, the carry out of the mantissa, overflow under each rounding, denormals.
7. **The square root to 64 bits**, by a root of a 128-bit number in integers
   (`sqrt80`), where it was the host's to 53. Newton's method in `long double` (`c_ld`)
   lands on these bits.
8. **The constants to 64 bits, and by the rounding**: FLDPI and the four logarithms were
   doubles. They are the chip's 64 bits cut off, one more when rounding to nearest (all
   but log2 of 10) or upward (all).
9. **FXTRACT, FPREM and FPREM1 in integers**: the mantissa kept whole; the remainder by
   long division, in parts when the exponents are 64 or more apart (C2 says so, and 32
   bits and the odd ones of the quotient are done), FPREM1 to the nearest with ties to
   even.
10. **FNSTENV and FNSAVE write ones in the upper half of the three words' places** in
    the 32-bit layout.

**The 32-bit machine.** Its suite then failed three traces, each at one instruction and
its consequences: the sign of zero by zero (`v_fpu1`) and the ones in the environment
(`v_fpu3`, `v_sse07`). Those traces were rustx86's. A small image run under KVM in 32-bit
protected mode said the real CPU does there what it does in long mode
(`FFFF037F FFFF0000 FFFFFFFF`, and 0/0 with its sign set). **The three expected traces
are now this machine's, which is to say the real CPU's, and `tools/difftest.sh` leaves
them alone when the rest are taken again from rustx86.** The other 160 lines are as they
were; so the Linux boots, X and the browser do not meet any of the ten.

**What was built besides.** `frd`, `fwr`, `fp_env32`, `fp_set_ax`, `fp_set_zpc`,
`fp_stop` in `src/exec.goose` and in `src/cpu64.goose`; the check of CR0's EM and TS
moved from the file to its two callers. FXSAVE and FXRSTOR in the 64-bit layout
(`src/sse64.goose`). In a machine: SSE is an undefined opcode until CR4.OSFXSR is set or
while CR0.EM is; x87 and SSE trap (vector 7) while CR0.TS is set; FWAIT traps only with
CR0.MP too; a fence never does. CPUID says FXSR.

**Wrong builds.** 37 (`build/mut98.py`). 25 caught at once; ten got cases (the stores'
ties, carry, overflow, denormals and NaNs; remainders in parts, at a tie, and of a
dividend between half the divisor and the whole; FNSAVE of a freed register); two were
wrong builds that did not build and were written again, and are caught. One changes
nothing: a REX prefix's bit in the register number, which the register stack's own
arithmetic drops.

**Not modelled, and not compared.** The status word's exception bits (the tests clear
them before reading it, as the card's third branch has it), exceptions unmasked, the
functions through the host's library (FSIN and the rest), FBLD and FBSTP (they stop the
run), FXSAVE's record of the last instruction.

**Next.** The kernel (E099).

## E099: a 64-bit Linux kernel, entered at its 64-bit entry point (2026-11-19)

M10's own aim ([roadmap.md](roadmap.md)): "A 64-bit Linux kernel boots to a shell".

- **Hypothesis**: Alpine 3.23's x86_64 kernel (`vmlinuz-lts`, 6.18.60; its boot header
  says it may be entered in 64-bit mode, 200h past where it is loaded) and an initramfs of
  Alpine's own busybox with a three-line `init` come up on the 64-bit machine as E091 to
  E098 left it, given a loader that does what the boot protocol asks of one (the kernel at
  16 MB, the first 4 GB mapped to themselves, a flat GDT, the zero page with a memory map,
  RSI pointing at it): **the kernel prints its messages on the serial port and busybox's
  shell prints its prompt.** What is missing shows as a stop that names an instruction or
  an MSR, since nothing unwritten passes silently; each is one thing to write.
- **What changed since last time**: everything so far was tests: at most a few thousand
  instructions each, every one compared with a real CPU. A kernel is some billions of
  instructions that nothing checks one by one. The 32-bit machine went the same way at M4.
- **Next move for each result**:
  - A stop that names something → write it, with a test against the real CPU where the
    thing is the CPU's (an instruction, a fault's shape) and without where it is a
    register that is only kept; go on
  - The kernel says what it lacks (a CPUID feature, a device) → give it, or tell it by
    the command line not to want it, whichever is true of this machine
  - Silence, or a panic with no stop → the count of instructions and the last address
    say where; a trace of the last thousand instructions before it; and if that does not
    say, the same kernel under QEMU with the same command line, to see what should have
    been printed next
  - Wrong and not stopped (a computation that differs) → the hardest kind: narrow by the
    kernel's own messages, then a test of the suspected instruction against the real CPU
- **Cut-off**: one CPU, 256 MB, the serial console; no ACPI, no local APIC (the kernel is
  told by CPUID that there is none), no disk and no network in this entry. A shell prompt
  and a few commands typed at it by a script are the end of it.

### Result

2026-11-19. **Kept: the kernel prints its messages on the serial port and busybox's shell
prints its prompt, 1,531 million instructions after the kernel is entered (51 seconds of
host time). `uname -a` typed at it says `Linux (none) 6.18.60-0-lts #1-Alpine SMP
PREEMPT_DYNAMIC ... x86_64 Linux`. M10's aim is met.**

It took three runs, and three things that E091 to E098 had not given:

| Run | How far | What stopped it | What was done |
|---|---|---|---|
| 1 | 666 million instructions: the kernel unpacked itself and began | a triple fault at RDMSR, before the kernel has a handler for anything | IA32_MISC_ENABLE (1A0h) is there and reads as 1; `--faults` was added to see which MSR |
| 2 | 1,506 million: every message of the boot, "Run /init as init process", `init`'s own line printed by busybox | VERW, "an instruction not written yet" (the kernel clears CPU buffers with it on the way back to a program) | VERR and VERW written; then `init` itself failed, for a busybox applet Alpine's does not have (`cttyhack`): one line of the initramfs's `init` |
| 3 | the prompt, and four commands | nothing | |

So the card's first branch three times, and none of the others: nothing was silent, and
nothing computed wrongly that showed. The whole of long mode's system side, the devices
and the x87 ran a kernel the first time they were asked to; what they had been asked
before was 37,558 instructions under ptrace and some hundreds of lines under KVM.

**What was built.**
- `src/linux64.goose`: the loader. The kernel at the address its header prefers (16 MB),
  the initramfs near the top of memory, the zero page with four lines of memory map, a
  GDT, six pages of tables mapping the first 4 GB to themselves, RSI, and RIP 200h into
  the kernel.
- `src/x64.goose`: a kernel is known by its header; `--initrd`, `--append`, `--wait`,
  `--type`, `--faults`; the serial port's output is printed as it comes. Memory is 256 MB
  (64 before: the kernel alone asks for 44 MB to unpack into).
- `tools/images/make-mini64.py`: takes busybox and musl out of Alpine's netboot
  initramfs and writes a cpio archive with them, an `init`, and two device nodes. 909 KB.
- In `src/sys64.goose`: VERR and VERW; three MSRs that an Intel CPU has and the kernel
  reads without asking (IA32_MISC_ENABLE, the platform's id, the microcode's revision:
  the last two answered with zero after the kernel's "unchecked MSR access" in run 2's
  messages). A 64-bit address is printed as sixteen digits, where `format_int` wrote the
  kernel's as negative numbers.

**Tested against the real CPU.** VERR and VERW in `y_fault`, on eight selectors (code,
data, level 3's, the TSS, null, past the table, one whose requested level is too low, a
system descriptor); five wrong builds, all caught, two after a selector each was added.
A ninth selector, one that names the LDT, was taken out: there is no LDT, and the real
CPU then reads whatever lies where one last was. The MSRs are registers that are only
kept and have no test.

**In the suite.** `tools/systest64.sh` boots the kernel when the two images are there,
types four commands and compares what they print (`x86_64`, `42` through a file in
/tmp, the count of processors, a status of 0); skipped when they are not.

**What the kernel says of this machine**, none of it wrong: no MTRRs, no PAT, no ACPI
tables, "APIC disabled by BIOS", SMP disabled, one processor at 76 MHz (64 instructions
to a tick of the timer), 210 MB of memory.

**Not done.** Everything in the roadmap's last paragraph on M10: the terminal as a
console, the disk, the network and the frame buffer behind this CPU, speed. And the name:
the roadmap says g86m becomes g64m when this stage is done, in one step, which is the
owner's to start.

## E100: the terminal as the 64-bit machine's console (2026-11-19)

After E099 the 64-bit Linux can be spoken to by script only. This is the first of what
the roadmap lists as missing on the 64-bit machine, chosen first so that the owner can use
it by hand.

- **Hypothesis**: The 32-bit machine's way (`run_serial` in `src/g86m.goose`, and
  `src/console.c` for the terminal's raw mode) carries over as it is: the machine runs a
  hundredth of a second of guest time, takes what was typed and gives it to the serial
  port, writes what the port sent, and sleeps when guest time is ahead of the clock, which
  it is whenever the guest is halted. **Started from a terminal with a kernel and no
  script, `x64` gives a shell that answers a typed command, takes three seconds of real
  time over `sleep 3`, uses almost no host CPU at the prompt, and leaves by Ctrl-] with
  the terminal's modes put back; `tools/console_test.py`'s Linux session, pointed at
  `x64`, passes unchanged but for the names.**
- **What changed since last time**: E099's serial output was printed every 16,384
  instructions and its input came from `--type`. The devices (and so the serial port's
  queue and its live output) are shared since E097; `console.c` has not been built into
  `x64` before.
- **Next move for each result**:
  - The session passes → kept; next is the disk behind this CPU
  - `sleep 3` takes much more than three seconds → the machine is not catching up with
    the clock while idle: look at how a halt moves virtual time (E097's `between`)
  - Much less → virtual time ran ahead and nothing slept: the pacing
  - Typed characters are lost or doubled → the port's queue against the kernel's
    interrupt handler; a wrong build of the interrupt path is the first thing to try
- **Cut-off**: the serial console only (no text screen, which a 64-bit kernel on this
  machine has no use for); the guest's CPU stays at 64 instructions to a timer tick, so
  that while it computes its clock runs behind the wall's (the host does some 30 million
  instructions a second and the guest counts 76 million to its second).

### Result

2026-11-19. **Kept, by the card's first branch: `tools/console_test.py`'s Linux session
passes on `build/x64` the first time it was run. Boot to the shell 49.8 seconds; a typed
`echo` answered; `sleep 3` took 3.00 seconds of real time; Ctrl-] left, with the
terminal's modes as they were.** At the prompt the machine used 0.40 seconds of host CPU
in 8 of real time (5%).

**What was built.** In `src/x64.goose`: `terminal_step`, called every hundredth of a
second of guest time: keys to the serial port's queue, the port's output written, and a
sleep of what guest time is ahead of the clock by (at most 50 ms at once); when the guest
is more than a fifth of a second behind, as while it computes, the two are set level
again. The terminal is taken when a kernel is started from one with no script and no
trace (`--headless` says never); the guest's clock then starts at the host's. The look at
the terminal or the script is now at the top of the loop, by a count of instructions that
a halt's jump in time cannot step over (E099's was "every 16,384th", which a jump could
miss). `src/console.c` is built into `x64`.

**A halt with the timer stopped** no longer ends the run when interrupts are on: time
passes a hundredth of a second at a time, so that a key can come in. A kernel with
nothing to wait for stops its timer. **This path did not run in the session**: the wrong
build that ends the run there passed. It is kept, and is not tested.

**Wrong builds**, through the same session: no sleep when ahead of the clock, and never
setting the two level, both make `sleep 3` take 0.11 seconds and are caught. (The second
is not obvious: without it the time lost during the boot is "owed", and the machine runs
ahead until it has made it up.)

**As the card's cut-off said**: the guest's clock was 32 seconds behind the host's after
a boot of 50 seconds, which the guest counted as 19.

**In the suite.** `tools/systest64.sh` runs the session after the scripted boot, when
the images are there.

**Next.** The disk behind this CPU.

## E101: the IDE disk behind the 64-bit CPU (2026-11-19)

- **Hypothesis**: The disk is `src/dev.goose`'s (E075), shared since E097 and never
  reached from the 64-bit CPU: it sits at ports 1F0h to 1F7h and interrupt line 14, and a
  driver talks to it with 16-bit port reads and writes repeated by REP INSW and REP OUTSW,
  which this CPU does not have yet. **With INS and OUTS written, and `--disk` given to
  `x64`, a test image that identifies the disk, reads sectors, writes one and reads it
  back prints the same as under KVM with the same image as QEMU's IDE disk: the size, the
  data, the status after each step and one interrupt for each command. And with the
  driver's modules in an initramfs, the 64-bit Linux mounts an ext2 file system from the
  disk and moves its root there, as the 32-bit one does (E075).**
- **What changed since last time**: E097's wrong builds of 16-bit and 32-bit port access
  were not caught, for want of a device that needs them; this is that device. The other
  side of the comparison is QEMU's model of a disk, not a CPU: where the two disks differ
  in something a driver does not depend on (the model's name, timings), that is not
  compared.
- **Next move for each result**:
  - The test prints the same and Linux mounts the disk → kept; next is the network
  - The status after a step differs → read what ATA says a drive does there; if this
    disk is wrong it is wrong for the 32-bit machine too: fix it there
  - The kernel does not find the disk → its messages say which probe failed; the 32-bit
    machine's `init` has the driver's options that worked (pata_legacy, the primary
    channel only)
- **Cut-off**: one disk, PIO only (no DMA: there is no PCI IDE controller), as on the
  32-bit machine. Alpine's x86_64 kernel has neither the ATA drivers nor ext2 built in
  (asked of the running kernel: no block file system in /proc/filesystems, no libata in
  /sys/module); they come from its `modloop-lts`, a download of 296 MB that is the
  owner's to allow. The first half of the hypothesis does not need it.

### Result (the first half)

2026-11-19. **The first half is kept: `y_ide`, 31 lines, prints the same on the 64-bit
machine with `--disk` as under KVM with the same image as QEMU's IDE disk, the first time
it was run.** The second half (Linux mounting the disk) waits for the owner's word on the
download the card names.

**What was built.** INS and OUTS (6C to 6F) in `src/cpu64.goose`, one repetition at a
time like the other strings, at 8, 16 and 32 bits; the page a repeated INS writes to is
asked for before the port is read, so that a fault does not lose what the device gave.
`--disk FILE` and `--keep` in `src/x64.goose`. The disk's data port is one port at 32
bits too (`io_in` and `io_out` took the upper half from port 1F2h). `tools/systest64.sh`
makes the test's disk image and gives it to both sides.

**The test**: the disk at rest; IDENTIFY (ATA, LBA, 2,048 sectors, one interrupt); two
sectors read, the first by single IN AX and REP INSW, the second by REP INSD, with the
status before and after and two interrupts; a sector written by OUT and REP OUTSW (no
interrupt before the data, one after), read back, its neighbours unchanged; a sector past
the end (the error bit); and a line sent to the serial port by REP OUTSB.

**Wrong builds.** 9 (`build/mut101.py`). 8 caught, one after the OUTSB line was added
(nothing had used OUTSB, and a build that took it for INSB passed). E097's two that no
device needed are among the caught: 16-bit access done as 8, and the upper half of a
32-bit read. One is still not: an 8-bit read done as a 16-bit one, which reads the next
port too and shows only where that has an effect; none of these ports has one that both
machines agree on.

**Nothing was wrong in the disk itself** (`src/dev.goose`, E075): QEMU's model and this
one give a driver the same.

### Result (the second half)

2026-11-19. **Kept: with the driver's modules in its initramfs the 64-bit Linux finds the
disk, mounts an ext2 file system from it and moves its root there, the first time it was
tried; and a file written before `off` is there at the next boot of the same image.** The
owner allowed the download (Alpine 3.23's x86_64 `modloop-lts`, 296 MB, kept outside the
repository as `images/modloop64-lts`).

```
scsi host0: pata_legacy
ata1: PATA max PIO4 cmd 0x1f0 ctl 0x3f6 irq 14 lpm-pol 0
ata1.00: ATA-6: g86m disk, 1, max PIO4
ata1.00: 65536 sectors, multi 1: LBA48
sd 0:0:0:0: [sda] 65536 512-byte logical blocks: (33.6 MB/32.0 MiB)
  g86m - busybox shell, root on /dev/sda
/dev/sda on / type ext2 (rw,relatime,errors=continue,user_xattr,acl)
```

1,907 million instructions to the shell on the disk (1,532 without one): the modules
loaded, the driver's probe, the mount and the move.

**What was built.** `tools/images/make-disk.sh` takes `ARCH=64`: the same seven modules
by the same names from the x86_64 modloop, busybox and musl from `images/initramfs64-mini`,
and makes `images/initramfs64-disk` and `images/disk64.img`. The `init` is the 32-bit
machine's file unchanged (`tools/images/init`), driver options and all.

**In the suite.** `tools/systest64.sh`, when the images are there: a boot from a copy of
the disk with `--keep`, a file written, `off`; a second boot that reads it.

**Rejected on the way.** The script's new variable had the name of one it already used
for a count, and the first images were called `disk7.img`. And a script's `--wait` for
"done-1" was met by the typed command's own echo, so the run ended before the answer: an
end marker has to be something the typed line does not contain (`done-$((1+1))`).

**Next.** The network behind this CPU.

## E102: the network behind the 64-bit CPU (2026-11-19)

- **Hypothesis**: The card (an NE2000 on PCI) and the gateway behind it (libslirp on the
  host) are `src/dev.goose`'s and `src/net.c`'s (E076), shared since E097, and what the
  64-bit kernel said at every boot so far, "PCI: Fatal: No config space access function
  found", was only that the PCI ports answer when there is a card. **With `--net` given
  to `x64` (the card set up, the network looked at every 40,000 instructions, and guest
  time held to the clock while the guest waits, which a reply from outside needs), and an
  initramfs with the card's driver, the 64-bit Linux finds the card on PCI, gets its
  address by DHCP, pings the gateway, and fetches a page over HTTPS with the TLS that
  Alpine's own initramfs carries.**
- **What changed since last time**: nothing of the devices; `x64` has had no option for
  the network and no look at it in its loop. The driver's modules (8390, ne2k-pci,
  af_packet) are in Alpine's netboot initramfs itself, so no more downloads.
- **Next move for each result**:
  - An address, the ping and the page → kept; next is the frame buffer
  - The kernel does not see the card → its PCI messages against what the 32-bit kernel
    prints with the same card; the 64-bit kernel may probe configuration space another
    way (it has more of them)
  - DHCP times out → the pacing: the guest's seconds must not go by faster than the
    host's while it waits (E076 met this)
  - TLS fails where plain HTTP works → an instruction of the 64-bit OpenSSL that no test
    has reached (it is compiled for SSE2 at least, and asks CPUID what else there is):
    the stop names it, or a test against the real CPU finds it
- **Cut-off**: one card; what the host's libslirp gives (no ping beyond the gateway).

### Result

2026-11-19. **Kept, by the card's first branch, at the first try of each part: the 64-bit
Linux finds the card on PCI, gets 10.0.2.15 by DHCP, pings the gateway three times of
three, and fetches `https://example.com/`.**

```
pci 0000:00:03.0: [10ec:8029] type 00 class 0x020000 conventional PCI endpoint
ne2k-pci 0000:00:03.0 eth0: RealTek RTL-8029(AS) found at 0xc000, IRQ 3, 52:54:00:12:34:56.
~ # wget -q -O - https://example.com/ | grep -o '<title>.*</title>'
<title>Example Domain</title>
```

With a card the kernel says "PCI: Using configuration type 1 for base access" where it
had said "Fatal: No config space access function found": as the hypothesis had it. The
64-bit OpenSSL ran with what E093 gave (SSE2 and no more: CPUID offers nothing later).

**What was built.** In `src/x64.goose`: `--net` (libslirp opened, the PCI bridge and the
card set up), a look at the network every 40,000 instructions, and `pace` taken out of
`terminal_step` so that a scripted run with a network is held to the clock too; `--rtc`
(host, or seconds since 1970), since a certificate is checked against the guest's date.
`tools/images/make-mini64.py` also makes `images/initramfs64-net`: the card's driver and
af_packet (which Alpine's netboot initramfs has, so the 296 MB of E101 were not needed
for this), busybox's DHCP script, `ssl_client`, OpenSSL's two libraries and the
certificates; its `init` is the 32-bit machine's shared one.

**In the suite.** `tools/systest64.sh`: the address and the ping, when libslirp and the
image are there; as on the 32-bit machine, nothing in the suite leaves the host. The
fetch over HTTPS was done by hand, once, with `--rtc host`.

**Not tested by a wrong build**: this entry wrote no device and no instruction; what it
wrote is the option and the loop's look, without which the suite's test has no card.

**Next.** The frame buffer behind this CPU; then speed.

## E103: a frame buffer behind the 64-bit CPU (2026-11-19)

The owner chose the screen before speed.

- **Hypothesis**: The 32-bit machine's screen (E078) is three things, none of them the
  CPU's: the loader tells the kernel of a frame buffer at the top of memory (the boot
  parameters' `screen_info`, as a boot loader that had asked the firmware would), the
  kernel's own driver draws on it, and `src/screen.c` shows that memory in a window and
  gives back keys and mouse moves, which go to the keyboard controller of `src/dev.goose`.
  **With the same lines in the 64-bit loader, `--fb` and `--shot` in `x64`, and the window
  opened when a terminal is there, the 64-bit kernel's console appears on the frame
  buffer: `/sys/class/graphics/fb0/virtual_size` says 1024,768, a saved frame has the
  console's text on it, and a line typed at the keyboard (scancodes through the 8042, not
  the serial port) reaches a program reading the console.**
- **What changed since last time**: nothing of the devices. What is not known is whether
  Alpine's x86_64 kernel has a driver for such a frame buffer built in, as its 32-bit
  kernel has efifb: E101 found that it has no disk driver built in.
- **Next move for each result**:
  - fb0 is there, the frame has text, the typed line arrives → kept; next is speed
  - No fb0 → what the kernel says of the frame buffer; if the driver is a module, it
    goes into the initramfs from the modloop of E101, loaded by `init`; if the kernel
    wants the frame buffer described another way (a different `screen_info` type), that
  - fb0 but a black frame → the pixel layout the kernel was told against what it draws
- **Cut-off**: the kernel's text console on the frame buffer, the window, the keyboard.
  X is not in this entry: it needs an x86_64 disk of X's packages (a download of its
  own) and, to be usable, the speed that comes next.

### Result

2026-11-19. **Kept, by the card's first branch: the 64-bit kernel has efifb built in, takes
the frame buffer the loader tells it of, and puts its console there, at the first try.
`virtual_size` says 1024,768; the saved frame shows the boot messages, a line a command
wrote to the console, and a line typed at the keyboard.**

```
efifb: framebuffer at 0xfd00000, using 3072k, total 3072k
efifb: mode is 1024x768x32, linelength=4096, pages=1
efifb: Truecolor: size=8:8:8:8, shift=0:8:16:24
fb0: EFI VGA frame buffer device
```

**What was built.** `src/linux64.goose`: the frame buffer taken off the top of memory,
its line in the memory map, and `screen_info`, the same fields as the 32-bit loader's.
`src/x64.goose`: `--fb WxH`, `--shot FILE`; the window (`src/screen.c`, now built into
`x64`) opened when a kernel with `--fb` is started from a terminal, looked at with the
terminal a hundred times a guest second, its keys and mouse moves going to the keyboard
controller; and two script steps, `--keys` (typed at the keyboard as scancodes) and
`--mouse`. The table of scancodes is a second copy of `src/console.goose`'s twenty lines,
which is the 32-bit machine's own file.

**The test's first version lost three characters**: "got-ed at the keyboard" for "typed
at the keyboard". The keys were sent before the program that reads the console had it
open, and a console nobody has open keeps nothing. The test now waits for a line that a
background `sleep 2` prints after the reader has started. The keyboard was right.

**In the suite.** `tools/systest64.sh`: the size, the typed line read back, and a saved
frame of the right length with more than 20,000 bytes that are not black.

**Not tested: the window.** It opens only from a terminal, on the host's screen, and no
script looks at it; the owner is to try it by hand, as with the 32-bit machine's (M8).
The mouse's script step moves the controller's mouse and nothing here reads it: the
kernel's mouse driver is a module, for when X is.

**Next.** Speed.

## E104: where the 64-bit machine's time goes: a survey before any change (2026-11-19)

The owner asked for a wide look before any work on speed, so that the work is not a
guess. Nothing is made faster in this entry.

- **Hypothesis**: The 64-bit CPU interprets, decoding every instruction every time into
  globals, at some 30 million instructions a second (E096: the loop; E099: 1.53 billion
  in 51 seconds). The guess to be tested, and it is only a guess: **more than half of the
  host's time is spent before an instruction's own work begins (fetching its bytes
  through the page tables one call at a time, the prefix loop, ModRM), and the code that
  runs is concentrated enough that remembering what was decoded would pay: fewer than
  100,000 distinct instruction addresses make up 99% of what a boot executes.** Both are
  what was true of the 32-bit machine (E010 on), and 64-bit code may differ: arguments in
  registers, REX on most instructions, a kernel that spends its boot unpacking and
  copying.
- **What changed since last time**: no measurement of the 64-bit machine exists beyond
  two wall-clock numbers. This counts, with a copy of the sources that has counters in
  it (nothing counted is in the real sources), on two stretches: the boot to the prompt,
  and a stretch of user programs after it (hashing, sorting, a loop in awk); and samples
  the host's stack on each.
- **What is counted**: host instructions and cycles for each guest instruction; the
  host's time by function; the guest's instructions by first byte, by length, by prefix,
  by kind of operand; memory reads, writes and fetches for each instruction, and how many
  miss the TLB; how the work divides between privilege levels; how concentrated the
  executed addresses are; how long a run of instructions is between two taken jumps, and
  what ends it; how often a fault, an interrupt, a system call, a write of CR3 comes.
- **Next move for each result**:
  - The fetch and decode are over half, and the addresses are concentrated → a decode
    cache first, as on the 32-bit machine, with the survey's numbers as its card's
    prediction
  - The time is elsewhere (the walk after CR3 writes, the save of the registers, the
    look between instructions, memory access itself) → that, first; the survey says how
    much it can give at most
  - The addresses are not concentrated (a boot that runs everything once) → the boot is
    the wrong thing to make fast; the stretch of user programs decides, and a decode
    cache is judged on it
  - Nothing stands out (a dozen things at 5% each) → no single change is worth a step of
    its own before a JIT; the survey becomes the list a JIT's design is checked against
- **Cut-off**: counting and sampling only. One sitting for the times. The counters' own
  cost is not in any time quoted: times come from the real build.

### Result

2026-11-19. **Both halves of the guess hold, the first by more than was guessed. Nine
tenths of the host's time goes before a guest instruction's own work begins or on finding
its operands (the guess was "more than half"); and 34,872 addresses make up 99% of the
boot's instructions, 7,668 of the user programs' (the guess was "fewer than 100,000").**
So the card's first branch: the work on speed begins with what is done before the
instruction, and a decode cache is right. The whole of it is in
[perf64.md](perf64.md); the figures that decide:

- **654 host instructions and 103 host cycles for one guest instruction**, on the boot;
  633 and 103 on user programs. The 32-bit interpreter takes 17.5 cycles (E090). The
  64-bit CPU is six times slower, instruction for instruction.
- Of the 654: the run loop in `main` 85, every time; `exec64` before it reaches the
  opcode's own code 165 to 208; fetching the bytes about 190 (a call through the page
  tables for each byte or constant, 3.2 an instruction); ModRM where used about 100; the
  instruction's own work 20 to 150.
- The TLB misses on 0.007% of fetches and 0.17% of data reads; an interrupt, a system
  call or a switch of address space comes once in 30,000 instructions.
- A 64-bit program reads or writes memory once in three instructions, runs 8 instructions
  between two taken jumps, and has REX on half of them.

**How it was counted.** Times and the host's counters from the real build
(`/usr/bin/time -l`). The host's time by function from `sample`, eight seconds on each
stretch. The 654 by part from a debugger stepping the host one instruction at a time
through eight guest instructions (`build/step.py`). The guest's side from a copy of the
sources with counters (`build/mkcount.py`: a table of every address executed, the first
bytes, lengths, prefixes, operands, TLB lookups and misses, events), run on the boot and
on the boot followed by the user programs, the second less the first
(`build/svreport.py`).

**Two things the first numbers were not.** The sample's hottest place, a third of all
samples at one store in `exec64`, is not where the time is: it is where the host comes
back to after the prefix loop's last jump, and stepping showed nothing costly there. And
the counting run's second stretch ran to its limit of 60 billion the first time: the
command had been passed through a file and lost its Enter.

**What was not measured**: how the parts overlap (a decode cache makes most of `exec64`'s
beginning unnecessary); anything under X, which this machine has not run; the cost of the
flags, which every arithmetic instruction computes whether or not they are read
(`alu` is 62 host instructions, 3% of the time).

**Next move**, by the card: the fetch (1 in the list of perf64.md), with the survey's
190 of 654 as its card's prediction.

## E105: an instruction's bytes read from its page, not fetched through the tables (2026-11-19)

The first of [perf64.md](perf64.md)'s list.

- **Hypothesis**: Every byte or constant of an instruction is a call of `code_rd`, through
  `sys_rd`, the TLB's lookup and `mem_rd`: 63 host instructions a call, 3.2 calls an
  instruction, about 190 of the 654 host instructions a guest instruction costs (E104).
  **If the page the instruction starts on is translated once (and kept while RIP stays on
  it at the same privilege level, until the TLB is emptied or a page forgotten), and the
  bytes that lie on that page are read from memory directly, a guest instruction costs
  under 500 host instructions, and the boot to the prompt takes at least a fifth less
  time (40 seconds or under, from 50.4).** What does not lie on the page (an instruction
  that runs across its end) goes the old way.
- **What changed since last time**: E104 measured and changed nothing. This is the
  32-bit machine's "code page" (E022), with two things it did not have to mind: the
  privilege level (the execute tables are two, E096) and the no-execute bit, both checked
  when the page is taken and not at each byte.
- **Next move for each result**:
  - Under 500 and a fifth less time, all tests as they were → kept; next is the run
    loop (2 in the list)
  - Fewer host instructions but not the time → the fetch was instructions and not
    cycles (the host ran them in parallel with something slower): look at cycles for
    each part before choosing the next, as E026 had to
  - A test differs → the page was kept across something that should have dropped it:
    that event joins the list of what forgets it, with a wrong build
- **Cut-off**: the fetch only. The run loop, `exec64`'s beginning and ModRM are as they
  were. Times in one sitting, three runs each.

### Result

2026-11-19. **Kept, by the card's first branch, and by more than it said: a guest
instruction costs 471 host instructions (654 before; the card said under 500) and 73 host
cycles (103), and the boot to the prompt takes 35.8 seconds (50.4; 29% less, where the
card said a fifth).** The boot runs the same 1,523,597,312 instructions and ends at the
same address.

| | Before | After |
|---|---:|---:|
| Boot to the prompt, three runs | 50.42 s | 35.88, 35.79, 35.68 s |
| Host instructions for a guest instruction (boot) | 654 | 471 |
| Host cycles for a guest instruction (boot) | 103 | 73 |
| Guest instructions a second | 30.2 million | 42.6 million |
| The loop of E096: host instructions for each of its 63 million | 703 | 537 |

The fetch was 190 of 654 by E104's stepping, and 183 went: what is left of it is a
compare and a load for each byte.

**What was built.** `code_fill` in `src/cpu64.goose`: the page RIP is on, translated for
executing (which is where the no-execute bit and the privilege level are checked), and
`fb`, `fw`, `fd`, `fq` and `peek8` reading from memory when all of what they want lies on
that page. Taken again when RIP is on another page or the privilege level is another;
forgotten by `tlb_flush` and `tlb_forget`. A page that is not in memory is never kept.

**Tests** (in `y_tlb`, against the real CPU under KVM; 70 lines now): a routine that
points its own page at another copy of itself and then writes CR3, or invalidates the
page, and says which copy it then is; an IRETQ at level 0 to the next instruction at
level 3 on a page that is level 0's; and MOV with a constant of two, four and eight bytes
lying across two pages that are not neighbours in memory.

**Wrong builds.** 9 (`build/mut105.py`). **Only one was caught by the tests as they
were** (the no-execute check): the system tests' code runs where linear and physical
addresses are the same, so a wrong page gave the right bytes. With the cases above 8 are
caught. The ninth changes nothing (what a fault during the fill leaves behind is never
used). A kernel's boot would have caught most, a minute at a time and without saying
where.

**Next**, by the card: the run loop.

## E106: one test between two instructions (2026-11-19)

The second of [perf64.md](perf64.md)'s list.

- **Hypothesis**: The run loop in `x64.goose` asks, before and after every instruction,
  whether the time has come for the timer, a look at the script or the terminal, a look
  at the network; whether the machine is halted or an interrupt is waiting; whether the
  instruction began with TF or followed an STI; whether a trace is wanted: 85 host
  instructions every time (E104), of the 471 a guest instruction now costs (E105), for
  things that happen once in 30,000 instructions. **If the loop works out once how many
  instructions it may run before the first of the timed things is due, and then runs
  them with one test after each ("has anything asked for attention": a flag the rare
  instructions set, a request from the interrupt controller with IF set, TF, the timer
  moved), a guest instruction costs under 420 host instructions and the boot takes 32
  seconds or under (35.8 now), with the same count of instructions at the same end.**
- **What changed since last time**: E105 took the fetch. This is the 32-bit machine's
  `run_until` (E024, E053): a moment worked out beforehand, and `replan` in
  `src/dev.goose`, which a write to the timer already sets for it.
- **Next move for each result**:
  - Under 420 and 32 seconds, all tests as they were → kept; next is `exec64`'s
    beginning, or the decode cache, whichever the new numbers favour
  - The count of instructions to the prompt changes → something timed is now seen at
    another instruction than before: find which, since a boot that depends on it would
    be hard to compare from here on
  - A system test differs (`y_irq` and `y_user` are the ones that watch the order of
    such things) → that event is not in the test after each instruction: it is added,
    with a wrong build
- **Cut-off**: a machine only, and not while tracing: a user-mode program's loop is as
  it was (its turn comes with M11).

### Result

2026-11-19. **Kept, by the card's first branch: a guest instruction costs 416 host
instructions (471) and 65 host cycles (73), and the boot to the prompt takes 31.8 seconds
(35.8; 11% less). The boot runs the same 1,523,597,312 instructions and ends at the same
address.**

| | E105 | Now |
|---|---:|---:|
| Boot to the prompt, three runs | 35.8 s | 31.85, 31.83, 31.64 s |
| Host instructions for a guest instruction | 471 | 416 |
| Host cycles for a guest instruction | 73 | 65 |
| Guest instructions a second | 42.6 million | 47.9 million |

The loop was 85 by E104's stepping and 55 went; what is left is the count, its store, and
the test.

**What was built.** In `src/x64.goose`: after the one instruction done with every
question asked (the loop as it was), a run: the count at which the first timed thing is
due (the script's or the terminal's look, the network's, the timer's tick), then
instructions with one test after each. `attn` in `src/cpu64.goose` is set by a halt, a
stop, an STI that sets IF, SYSCALL and SYSRET. The devices' time is set when a port is
used, where it was set before every instruction.

**Tests added** (against the real CPU, in `y_user` and `y_irq`): TF set by POPF straight
after STI, and straight after a SYSRET that did not set it (the first single step is
after the instruction that follows the POPF, whatever came just before); STI straight
after the timer is written to (still not before the instruction that follows).

**Wrong builds.** 15 (`build/mut106.py`). 8 caught, three of them after the cases above.
**Seven are not, and for one reason: what they change is when, not what.** A halt that
does not look up spins where it should sleep; a request seen with IF clear, or no heed of
a write to the timer, or the devices' time not set at a port, or STI's shadow carried
into the run when no request is waiting, move an event by some instructions; and running
on after the stop runs a few instructions that print nothing. No test that prints the
same on a real CPU twice can tell, since a real CPU's timing is its own. They are kept
right by reading, and the boot's count of instructions (unchanged here) is the one
number that would move with some of them.

**Rejected on the way.** A case that the write which stops the machine stops it at once:
under KVM two more characters were printed after it, since QEMU's device ends the guest
when it gets round to it. That is QEMU's, not a CPU's, and the case was taken out.

**Next.** `exec64`'s beginning is now the largest part (165 to 208 of 416), and a decode
cache would take most of it and of ModRM: the decode cache, with what of the beginning
it does not cover.

## E107: a decode cache for the 64-bit CPU: the prefixes and ModRM remembered (2026-11-19)

The fourth of [perf64.md](perf64.md)'s list, begun before the third: after E105 and E106
`exec64` itself is 177 to 222 of the 416 host instructions a guest instruction costs
(stepped again: a taken JNZ is 257 in all, 177 of them `exec64`'s; `add rbx, rax` is 422,
with 191 and ModRM's 46 + 31 + 22 + 19 + 18).

- **Hypothesis**: Two parts of an instruction's cost depend only on its bytes, and E104
  found the bytes at an address almost never change (addresses run fewer than 8 times are
  0.02% of what is executed): the prefix loop (a fetch and eleven comparisons for each
  prefix byte, twice for the half of instructions that have REX), and the parsing of
  ModRM, SIB and displacement (`modrm`, 46 to 68, with its fetches). **With a table found
  by the instruction's physical address that remembers the prefixes, the opcode, and what
  `modrm` worked out (the three fields, the registers and scale of the address, the
  displacement, where the operand ends), a guest instruction costs under 380 host
  instructions and the boot takes 29.5 seconds or under (31.8 now).** An entry is good
  while the page it was made from is not written to: pages that hold entries are marked,
  and a write to one drops its entries (the 32-bit machine's way for 32-bit code, E044).
- **What changed since last time**: E105 and E106 took what was outside the instruction.
  This is the first structure: a table, and a watch on writes. It is also what the next
  step stands on: an entry that also says which of a few dozen common forms the
  instruction is, so that those skip `exec64`'s chain of comparisons too (the 32-bit
  machine's short executors). That step is not in this entry.
- **Next move for each result**:
  - Under 380 and all tests as they were → kept; next is the common forms, on this table
  - Over 380 but under 416 → the lookup and the watch cost more than was thought: kept
    if the tests hold, since the next step needs it, and the ledger says what it cost
  - No gain or a loss → the table as built is in the way: count its lookup, and whether
    writes to marked pages are common (the kernel patches itself at boot), before
    anything is built on it
  - A test differs → an entry outlived its bytes, or was made from bytes that are not
    all on its page: the case goes into the tests with a wrong build
- **Cut-off**: the prefixes and ModRM only. Constants are read from the page each time
  (which E105 made cheap); the opcode's arm is still found by `exec64`'s comparisons.
  `--no-decode-cache` turns it off, for looking for a fault in it.

**Result: 399 host instructions for a guest instruction (416 before), and the boot in 31.4
to 31.9 seconds (31.8 before): the card's second branch. Kept, and what it cost is below.**

| Boot to the prompt (1,523,597,312 instructions) | Host instructions | Cycles | Time |
|---|---:|---:|---:|
| E106 | 634 thousand million (416 each) | 99.2 | 31.8 s |
| this entry, the cache on | 608 (399) | 96.8 to 97.1 | 31.4 to 31.9 s |
| this entry, `--no-decode-cache` | 680 (447) | 109.8 to 110.1 | 35.1 to 35.2 s |

- **The table works as E104 said it would.** Counted in a build with counters: 97.1% of
  instructions are found (1,479,755,533), 2,630,988 are decoded and remembered, 41,201,435
  begin on a page that has been given up or lie across two; `modrm` takes what it needs
  from the entry 1,139,895,519 times and parses 32,393,842 times. Pages are dropped 1,741
  times in the boot and 9 pages are given up (code and data on one page).
- **It saves 48 and its upkeep costs 31.** With the cache turned off the same build needs
  447, not E106's 416: the watch in every store, the entry's index kept for `modrm`, and
  the branch around the old decoder are paid whether an entry is found or not. Found, the
  entry saves 48 of the 447. The estimate was wrong in both halves: the prefix loop and
  `modrm` were less than was counted, and the upkeep was not counted at all.
- **Why a found entry is not cheap** (one guest instruction's host instructions written
  out, a `ret`: 368, of them `exec64` 186): each field of the entry is unpacked into a
  global of its own (`rex`, `p66`, `asz32`, `rep`, `seg_base`, `ip`, then `m_mod`, `m_reg`,
  `m_rm`, `m_off`, `m_ea`), and the globals lie on both sides of the 256 MB of memory, so
  each store is three or four host instructions; `exec64` then tests those globals again.
  What the same listing shows beside it: `exec64` saves twelve registers on entry and
  restores them; the start of the instruction is saved (17 words) every time; and reading
  the eight bytes of the return address is 72 host instructions in `mem_rd`, which tests
  and loads each byte by itself, after 49 in `sys_rd`.
- **Held to the real CPU.** A new program, `a_smc` (1,028 instructions traced on the real
  CPU by ptrace): an instruction run three times, then its opcode, its ModRM, its
  displacement, a prefix, its REX prefix or its RIP-relative address changed and run three
  times more; stores that begin on the page before the code's; code far into a page; an
  instruction on two pages changed on the second; a store beside code forty times (the
  page is given up). In `y_tlb` (75 lines, from KVM): code changed through another
  address of its page, and FS's base in an instruction that repeats. 18 programs and 8
  system tests pass, and the kernel boots its four ways.
- **Wrong builds: 15 of 15 caught**, 8 of them at first. The seven that passed showed the
  tests' holes, not the cache's: nothing ran code in the upper half of a page; nothing
  changed the second page of an instruction on two; no page was reached at an address
  other than its physical one and then changed; and the repeated instructions sat on a
  page with data, which the stores had given up, so that what `modrm` remembers (the
  constant after a RIP-relative address, an address of 32 bits, a segment's base) was
  never used twice. Each has its case now. One wrong build was itself wrong the first
  time (it changed the tag looked for and not the tag stored, and so found nothing).
- **Not caught by anything but the boot**: an entry depends on nothing but the bytes,
  because this CPU runs 64-bit code only. A second mode would have to be part of the tag.

**Next.** The listing names three things that cost more than the table saves, none of
them a structure: `mem_rd` and `mem_wr` a word at a time (72 host instructions for eight
bytes now); the instruction's state in a few locals or one small record instead of
globals far apart; the start of the instruction saved only when something can fault.
After those, the common forms on this table, as the card said.

## E108: memory read and written a word at a time (2026-11-19)

- **Hypothesis**: E107's listing of one `ret`: the eight bytes of the return address cost
  72 host instructions in `mem_rd` (each byte's index tested against the block's size,
  each byte loaded by itself), after 49 in `sys_rd` (twelve registers saved for a loop
  that only an access across two pages runs) and before `pop`'s 28. The 32-bit machine
  has had this since E061: one test of the whole access, after which the compiler makes
  the byte loads one load (`mem32` in state.goose). **With one test for the whole access
  in `mem_rd` and `mem_wr`, and the access across two pages moved out of `sys_rd` and
  `sys_wr` into functions of its own, a guest instruction costs under 375 host
  instructions (399 now) and the boot takes 30 seconds or under (31.4 to 31.9).**
- **What changed since last time**: E107 added a structure and its listing showed that
  plain memory access costs more than the structure saves. Nothing is added here: the same
  functions, the same order of translation, faults and stores; fewer tests.
- **Next move for each result**:
  - Under 375 → kept; next is the instruction's state near at hand (E107's second item),
    measured the same way
  - 375 to 399 → kept if the tests hold; step one read and one store again to see what is
    left in them (the TLB's index, the decode cache's watch) before going on
  - No change → the compiler had merged the loads elsewhere and the listing's `ret` was
    not typical: count accesses by width before anything else
  - A test differs → a width or the page's end is wrong: the case into `y_paging`
- **Cut-off**: `mem_rd`, `mem_wr`, `sys_rd`, `sys_wr` and `rd`/`wr` only. The stack
  functions, the strings and the TLB's layout stay as they are.

**Result: 378 host instructions for a guest instruction (399 before), and the boot in 29.4
to 30.3 seconds (31.4 to 31.9): the card's second branch, by three instructions. Kept.**

| Boot to the prompt (1,523,597,312 instructions) | Host instructions | Cycles | Time |
|---|---:|---:|---:|
| E107 | 608 thousand million (399 each) | 96.8 to 97.1 | 31.4 to 31.9 s |
| this entry | 575 (378) | 92.4 to 93.0 | 29.4 to 30.3 s |

- **Writing "one test" was not enough; the compiler had to be led.** Each step was read
  in the compiled code before it was measured:
  - One test of the whole access, and the bytes still loaded one by one: 393. Where two
    widths both begin with the byte at the address, the compiler takes that load out in
    front of the test of the width, and what is left in each arm is no longer a pattern it
    makes one load of. Eight bytes read from the top byte down, and four in a function of
    their own: `mem_rd` is one `ldr` for each width (25 host instructions in all, 72
    executed before for eight bytes).
  - The access across two pages in a function of its own: put back by the compiler, since
    it had one caller. Goose keeps a callee out of line when it is called from an arm that
    ends in `return` while the other path goes on (its implementation notes, "cold
    branch"): the test turned round, and `rd` is one function of 87 host instructions
    that saves two registers, where `sys_rd` saved twelve. 379.
  - The store to a marked page the same way (`mem_wr_marked`): 378.
  - A store of eight bytes: the lower four are one `str`, the upper four become about
    fifteen vector instructions. Three other ways of writing it were tried (top byte down;
    under a test of its own; a function of its own) and compiled the same; a fourth (the
    upper half through a variable mask) gave four byte stores and 0.07%. Left as it is.
- **Held to the real CPU.** 18 programs and 8 system tests pass and the kernel boots its
  four ways. New in `y_tlb` (83 lines, from KVM): stores and loads of eight, four and two
  bytes that reach exactly one byte into the next page, where the two pages are not
  neighbours in memory.
- **Wrong builds: 14 of 14 caught**, 13 at first. The one that passed (a store that
  crosses by one byte taken as not crossing) had no test: the stores across a page in the
  tests crossed by two bytes or more. A fifteenth was no wrong build (an access that
  exactly fits sent the long way gives the same result).
- **The wrong builds' script filled memory** (870 MB before the owner saw it): a wrong
  build that never reaches its end prints its trace without end, and the script kept all
  of it. It now reads no more than the expected text and one byte, and gives the trace
  runs a limit of instructions.

**Next.** As the card said for this branch, what is left in an access, read from the
compiled code: `rd` is the test for a machine, the page's end, the TLB's index (which
table, by the kind of access and the privilege level), tag and load, then `mem_rd`'s test
of the block's end and the width: about 30 executed for a read that was 150. The larger
part of the 378 is `exec64` itself again. Next is E107's second item, the instruction's
state near at hand, and with it the twelve registers `exec64` saves.

## E109: the decoded instruction in one place (2026-11-20)

`exec64` itself is 200 of the host instructions a guest instruction costs (stepped through
178 consecutive instructions of the boot: 337 for each there, 378 over the whole boot).
132 of the 200 run for every instruction, whatever it is:

| Part of `exec64` every instruction runs | Host instructions |
|---|---:|
| Saving and restoring twelve registers | 16 |
| The checks for a machine and a pending interrupt | 8 |
| `save_start` (sixteen registers, the flags, the level) | 18 |
| Is RIP on the code page, at the same level | 20 |
| Finding the decode cache's entry (three arrays) | 30 |
| Unpacking it into `rex`, `p66`, `asz32`, `rep`, `seg_base`, `ip` | 33 |
| `osz`, the width, the masks for it, clearing RF | 30 |

The unpacking stores each field into a global of its own, and the globals lie so far apart
(the memory and the cache's arrays between them) that each store builds its address with two
instructions more. `modrm` (48 for a call, 0.67 calls an instruction) unpacks its fields
the same way.

- **Hypothesis**: **with the decoded fields kept in the cache in the form they are used in
  (a struct of bytes and one displacement, 24 bytes), and the instruction at hand a copy of
  that struct, a hit is one copy and no unpacking; the tag in the same entry makes the
  lookup one address. The boot takes under 345 host instructions for a guest instruction
  (378 now).**
- **What changed since last time**: E107 and E108 added the cache and made memory access
  short; this is the first change to how `exec64` holds what it decoded. No new structure:
  the same cache, the same tag, the same drops; its entry laid out differently.
- **Next move for each result**:
  - Under 345 → kept; next is the twelve registers: a short front for the commonest
    opcodes that needs few of them, the rest as now
  - 345 to 365 → kept if the tests hold; read the compiled copy and lookup again (a copy
    of 24 bytes that became byte moves, or the fields loaded back one by one, would say why)
  - No change → the far stores were not the cost: the table above is wrong somewhere, step
    again before anything else
  - A test differs → a field is stale on a hit (the segment's base is the one that is
    not constant: it is taken from FS or GS at each use, not remembered)
- **Cut-off**: the layout of the decoded state and of the cache's entry, in `exec64` and
  `modrm`. `save_start`, the run loop and the split of `exec64` are other entries.

**Result: 333 host instructions for a guest instruction (378 before), and the boot in 27.5
to 27.8 seconds (29.4 to 30.3): the card's first branch. Kept.**

| Boot to the prompt (1,523,597,312 instructions) | Host instructions | Cycles | Time |
|---|---:|---:|---:|
| E108 | 575 thousand million (378 each) | 92.4 to 93.0 | 29.4 to 30.3 s |
| this entry | 507 (333) | 85.5 to 85.6 | 27.5 to 27.8 s |
| this entry, `--no-decode-cache` | 638 (419; 447 at E107) | 102.6 | 34.3 s |

- **What was done.** The decoded instruction is a struct `Ins` of 24 bytes (sixteen fields
  of a byte, and the displacement), the cache's entry is that struct with the tag in front
  (32 bytes, one array where there were three), and the instruction at hand, `ins`, is a
  copy of the entry's. The operand size is worked out when the instruction is decoded and
  kept. The segment's base is not kept: `seg_base()` reads FS's or GS's base when an
  address is made (the card's fourth branch named it as the field that can go stale).
- **Read in the compiled code**, stepped as before (198 consecutive instructions of the
  boot, 303 for each there): a hit is the tag's compare, one load and store of sixteen
  bytes and one of eight; no field is unpacked. `exec64` itself 166 (200), `modrm` 34 for
  a call (48).
- **Held to the real CPU.** 18 programs and 8 system tests pass and the kernel boots its
  four ways; the expected results are the ones taken before this entry.
- **Wrong builds: 20 of 23 caught.** The three that passed:
  - *The prefix 67h not cleared for the next instruction* (when that one is decoded for
    the first time). No test has an address above 32 bits after an instruction with 67h:
    the hole is older than this entry.
  - *REX.R left in the x87's operation field.* No test puts REX in front of an escape
    opcode.
  - *REX.B left in the x87's register field.* The same hole; and on three register forms
    it gave the right build's result, so it may be no wrong build at all (not looked into).
- **The test for those: `a_prefix`, 36 traced instructions, and all 23 are caught.** An
  instruction met for the first time after one with 67h, 66h, REX.W and F3h; REX in front
  of five x87 instructions (register forms, a memory form, and FLD1, where the register
  field is part of the opcode). The right build gave the real CPU's trace at the first
  run. The third wrong build was a wrong build after all: the x87's code takes a register
  number modulo 8, so REX.B left in it named the same register, but FLD1 with REX.B was
  taken for an opcode that does not exist. The first version of the test had no such
  instruction.
- **A wrong reading on the way, corrected.** The test was first written when the oracle's
  host did not answer, set aside under `tests/asm64/pending/`, and the entry said the host
  could not be reached. It had been up all along (32 days); the machine this was run on
  was on another network for that half hour. The wake-on-LAN packets sent then did
  nothing.

**Next.** As the card said for this branch: the twelve registers `exec64` saves and
restores (16), with `save_start` (18) the largest things every instruction still pays
before its own work. A short front for the commonest opcodes that needs few registers,
the rest as now.

## E110: a short front for the commonest instructions (2026-11-20)

What every instruction still pays in `exec64` before its own work (E109's stepping, 166
host instructions in `exec64` for each guest instruction): twelve registers saved and
restored (16), the start saved in case of a fault (`save_start`, 18: sixteen registers,
the flags, the level), the code page's test, the lookup and copy, and the way to the
opcode's arm through `op`'s tests.

- **Hypothesis**: **an instruction found in the decode cache whose kind is one of a dozen
  (ALU with ModRM, MOV, the group 80h/81h/83h, TEST, LEA, MOVZX, PUSH, POP, CALL, RET, Jcc
  and JMP) can be run at the top of `exec64`, by a jump on a kind kept in its entry,
  without saving the registers: none of these changes a register before the last point it
  can fault at. The rest of `exec64` becomes a function of its own that the front calls
  for everything else. The boot takes under 315 host instructions for a guest instruction
  (333 now).**
- **What changed since last time**: E109 changed how the decoded instruction is held;
  this is the first change to the order of work in `exec64`, and the first time the
  start of an instruction is not saved in full. The fault path must know which it was.
- **Next move for each result**:
  - Under 315 → kept; step again and see what the front still pays (the code page's test
    and the checks for a machine come next), and which kinds are missing by count
  - 315 to 333 → kept if the tests hold; read the front's compiled code: if it still
    saves twelve registers the split did not take, and the front is to be made smaller
  - No change or worse → the front's instructions were not the common ones here, or the
    second call costs what the save did: count kinds before anything else
  - A test differs → a kind changes a register before a fault after all, or the fault
    path restores what was not saved: the case into `y_fault`
- **Cut-off**: the kinds named above, in `exec64` and the fault path. No change to
  `modrm`, `alu`, the memory functions or the run loop.

**Result: 289 host instructions for a guest instruction (333 before), and the boot in 24.4
to 24.7 seconds (27.5 to 27.8): the card's first branch. Kept.**

| Boot to the prompt (1,523,597,312 instructions) | Host instructions | Cycles | Time |
|---|---:|---:|---:|
| E109 | 507 thousand million (333 each) | 85.5 to 85.6 | 27.5 to 27.8 s |
| this entry | 440 (289) | 76.6 to 76.8 | 24.4 to 24.7 s |
| this entry, `--no-decode-cache` | 667 (438; 419 at E109) | | 37.5 s |

It came in four steps, each measured:

| Step | Host instructions for each |
|---|---:|
| E109 | 333 |
| The front as the card had it: run on a hit, the rest called for all else | 328 |
| The globals every instruction uses declared together, in front of the memory | 315 |
| Two tests taken out of the lookup (is the cache on, is there a code page) | 308 |
| The front run for its kinds the first time too, and the two-byte opcodes given their kinds | 289 |

- **The first measurement was the card's second branch (328), and the compiled front said
  why.** It saved ten registers where `exec64` had saved twelve, and a third of the
  instructions paid for both functions. What it showed besides: every use of a global on
  the far side of the 256 MB of memory took two host instructions more to build its
  address. The globals lie in the order they are declared; the dozen that every
  instruction reads are now declared together in front of the memory. 13 host
  instructions, and no cycles: the count went down and the time did not.
- **The wrong builds found that the front was hardly tested, and that part of it had never
  run.** 16 of 28 passed at first. The front ran an instruction only when it was found in
  the cache, the second time it is met, and most test programs run each instruction once;
  the first time, the same opcodes went through arms of their own in the rest. And
  `kind_of` tested "below 40h" before "is 0Fh", so MOVZX and the near Jcc never had a
  kind: the front's arms for them were dead, and nothing said so because the rest ran
  them correctly. Both are one mistake: two implementations of one instruction, of which
  the tests saw one.
- **So there is one implementation now.** An instruction of a kind is run by the front
  whether it was in the cache or has just been decoded (`decode` is a function of its
  own, `exec64_miss` calls it), and the rest has no arms for those opcodes. With the
  two-byte opcodes in, 86% of the instructions go through the front (of 219 consecutive
  ones of the boot, stepped; not counted over the whole boot); that step was the largest
  (308 to 289).
- **The start of an instruction is saved in full only by the rest.** The front saves the
  flags and clears `start_saved`; a fault puts back the registers and the level only if
  they were saved. A fault or interrupt that is waiting is delivered after a full save.
- **Held to the real CPU.** 19 programs and 8 system tests pass and the kernel boots its
  four ways. New, with expected text from KVM: in `y_fault`, a fault's handler returns
  with TF set, and the flags pushed for the single step after the next instruction have
  no RF; in `y_tlb`, LEA with FS in front, and a RET to an address above 4 GB.
- **Wrong builds: 25 of 27 caught**, 22 before the three new cases. The two that pass:
  - *No full save before a waiting fault is delivered.* Delivery changes only the level
    before it can fault, and what follows a fault in delivery is a double fault, which
    shows nothing of the level it started at when it has a stack of its own, and ends the
    run when it has none. No case that prints a difference was found.
  - *The delta that makes the lookup find nothing where there is no code page, off by
    one.* A code page is missing only for code outside the machine's memory, which no
    test runs: what the real CPU reads there depends on how much memory it has.
- **`--no-decode-cache` is slower than before** (438, 419 at E109): without the cache
  every instruction is decoded, classified and then run, through two functions. It is a
  switch for comparing, not a way to run.

**Next.** Stepped through those 219 instructions (274 for each there): `exec64` 110 and
the rest 17, where E109 had 166; `main` 31, `modrm` 29, `alu` 23. The front still pays the checks for a machine and a waiting fault, the
code page's test (and the level's), and ten registers. What the count no longer shows is
where the cycles go: the globals' step took 13 instructions and no time. The next entry
is to begin from cycles (the jump on the kind, the loads that follow the copy of `ins`),
not from the instruction count.

## E111: where the cycles go (a survey; 2026-11-20)

E110's step that moved the globals took 13 host instructions from each guest instruction
and no time. The count has been the measure since E104; it stops being one when what is
removed ran beside something slower. The boot now takes 289 host instructions and 50.3
cycles for a guest instruction: 5.7 instructions a cycle, which is near what this CPU
can retire. So little is waiting on a wrong guess of a branch or on memory that is not in
the cache, and what sets the time is more likely the longest chain of things that wait
for each other.

- **Hypothesis**: **the time of a guest instruction is set by one chain through memory:
  RIP is loaded, the cache's entry found from it and copied to `ins`, fields loaded back
  from `ins`, the arm jumped to, the registers loaded and stored in the array, RIP stored,
  and the next instruction begins by loading it. Sampled by host address, more than half
  of `exec64`'s samples lie on instructions that wait for a load of something stored a
  moment before (RIP, `ins`, `ip`, a register), and under a tenth just after the jump on
  the kind.**
- **What changed since last time**: the measure. Samples of time by host address instead
  of counted instructions; nothing in the program changes in this entry.
- **Next move for each result**:
  - The chain (as the hypothesis says) → the next entry keeps what the chain passes
    through in locals across the front: RIP and `ip` in registers, the fields used from
    the entry and not from the copy, one store of RIP at the end
  - The jump on the kind has a fifth or more → the guess of where it goes is what costs:
    the next entry is about the jump (one jump for each kind's most frequent successor,
    or the commonest kinds tested before the table)
  - Spread evenly, no instruction with more than a few percent → the count is the measure
    after all and the 13 were a coincidence: go on by count, with `main` (31) and `modrm`
    (29) next
  - Elsewhere (`alu`, `modrm`, the memory functions) → that function's entry comes first
- **Cut-off**: the boot, one sampling run of 20 seconds and one built condition to tell
  the first two branches apart. A survey: no change to `src/`.

**Result: the hypothesis is rejected as written, and what holds is the card's third branch
with one exception. The time is where the instructions are; the one place where it is
not is the load of the decode cache's entry, which takes about a tenth of the boot's
time.**

How it was measured: the running program stopped 6,000 times, about 3 ms apart, and its
program counter read (`lldb`; 17 minutes for 18 seconds of running). A stop finds the
instruction the CPU is waiting to finish, so an instruction that waits for memory, or the
first one after a jump guessed wrong, collects the samples of what stands behind it.

| Function | Share of the samples (boot) | Share of the host instructions (E110's stepping) |
|---|---:|---:|
| `exec64` | 48.3% | 40% |
| `main` | 10.9% | 11% |
| `modrm` | 9.2% | 11% |
| `exec64_rest` | 6.2% | 6% |
| `alu` | 5.4% | 8% |
| `rm_get`, `fs8`, `rd`, `wr`, `sr`, the rest | 20% | 24% |

| In `exec64` (2,898 samples) | Samples | Of all the boot's time |
|---|---:|---:|
| The entry's tag loaded and compared (two instructions) | 675 | 11.3% |
| The kind read back from the copy and tested | 382 | 6.4% |
| The rest of the lookup (hash, the copy's second half) | 74 | 1.2% |
| First instructions after the jump on the kind, and other targets of jumps | 497 | 8.3% |
| The code page's test | 262 | 4.4% |
| Restoring the registers and returning | 187 | 3.1% |
| The checks for a machine and a waiting fault | 176 | 2.9% |

- **Not a chain of stores read back.** RIP, `ip` and the registers read back after they
  were stored collect nothing to speak of; the one such load that does is the kind's
  byte, read from a copy made by a store of sixteen bytes just before (6.4%).
- **The jump on the kind is under a tenth**, counting every target of a jump in `exec64`
  as if the guess had been wrong: the card's second branch is out.
- **The built condition: a loop of five instructions of the front's kinds, two thousand
  million of them** (`add`, `mov`, `xor`, `sub`, `jnz`; nothing leaves the nearest cache
  and every jump goes where it went before). 295 host instructions and 45.5 cycles for a
  guest instruction, where the boot has 289 and 50.3. So nine tenths of the boot's
  cycles are there when nothing waits: 6.5 host instructions a cycle is what this CPU
  does with this code, and fewer instructions is still what makes it faster. In the loop
  the tag's load and compare have 5.6% of the samples, in the boot 11.3%: the difference,
  about 6% of the boot's time, is the entry not being near. 5,289 addresses make up 90%
  of the boot's instructions (E104), an entry is 32 bytes and, the globals being packed,
  begins at an odd address, so half of them lie across two lines of the cache; and the
  hash keeps an entry for each byte address, so instructions next to each other have
  entries 100 bytes apart.
- **Why the globals' step took no time** is not explained by this entry. The
  instructions it removed (two for each far address) depend on nothing and wait for
  nothing; that they cost nothing fits, but it was not measured here.
- **Not measured**: user programs (the boot only); how often the jump on the kind is
  guessed wrong (no counter was read; the 8.3% is an upper bound from where samples
  fall). The sampling tool is `build/pcsample.py`, not kept in the repository.

**Next, in this order.**
1. The decode cache's entry near: the array begun on a line of the cache (64 bytes), so
   that no entry lies across two; then whether the kind can be tested from the entry and
   not from the copy. Measured in cycles, since the count will hardly move.
2. Then by count again, where the samples and the count agree: `main`'s loop (31
   instructions, 11% of the time) and `modrm` (29, 9%).

## E112: the primitives (a survey; 2026-11-20)

The owner's proposal: not benchmarks, which measure a mixture, but the things a program
is made of, one small C program for each, built with GCC as real programs are. What is
made faster for a primitive is faster in every program that has it. The list (23, in
`tests/prim64/`): loop, if, the conditional operator, pointer, recursion, pointer to a
function, switch, arrays and structures, multiply and divide, bytes; double (arithmetic,
comparison, conversion), float, long double; shifts, rotating and bit searching, bit
fields; filling and copying, pixels one at a time, pixels several at a time; a hash,
large numbers.

All 23 print on g86m what they print on the real CPU (they were run there, natively, for
the expected text). That was not known before this entry for the last three groups.

- **Hypothesis**: **the primitives differ by more than a factor of two in host
  instructions for a guest instruction, and the expensive ones are those whose
  instructions the short front does not run: the pointer to a function and the switch
  (an indirect CALL and JMP), the conditional operator (CMOV, SETcc), the shifts, and
  everything in XMM registers.**
- **What changed since last time**: the boot was the only measure (one number, 289).
  This is one number for each primitive, and for each the list of instructions that go
  to the rest of the CPU.
- **Next move for each result**:
  - As the hypothesis says → the instructions that keep a primitive out of the front go
    into it, in the order of (their share in the primitive) × (how common the primitive
    is in the boot and the user programs, E104); one entry for each group
  - All within a factor of 1.3 → the front is not what tells them apart; the cost is in
    what all share (the lookup, the run loop, `modrm`), and E111's list stands
  - A primitive is expensive with all its instructions in the front → its cost is in the
    front's helpers (`alu`, `rm_get`, memory): that function's entry comes first
- **Cut-off**: the programs as written, each run once in user mode (no paging), counted
  once. No change to how instructions are run in this entry.

**Result: the primitives lie between 291 and 477 host instructions for a guest instruction,
a factor of 1.6 and not the two the card said; and the short front is not what tells the
integer ones apart. The expensive ones are four groups: the string instructions with a
repeat count, division, everything in XMM registers, and the x87.**

Each program run once in user mode (`tools/prim64_table.py`; the counts of what the front
does not run come from a counting copy of the sources it makes):

| Primitive | Guest instructions | Host instructions for each | Cycles for each | Run by the front | What the front does not run (share of the program's instructions) |
|---|---:|---:|---:|---:|---|
| `p_if` | 23.0 million | 291 | 51.2 | 100% |  |
| `p_switch` | 25.8 million | 291 | 54.0 | 84% | CMP A, imm 10%, JMP-indirect 4%, NOP 1%, SHR 1% |
| `p_rotate` | 89.5 million | 293 | 47.3 | 91% | SHR 3%, MOVSXD 1%, ROL 1%, SHL 1%, MOV r, imm 1% |
| `p_funcptr` | 20.9 million | 303 | 54.5 | 85% | CALL-indirect 12%, NOT 1%, SHR 1% |
| `p_recursion` | 12.2 million | 303 | 56.1 | 99% | MOV r, imm 1% |
| `p_bytes` | 34.6 million | 309 | 52.8 | 89% | SETcc 7%, CMOVcc 4% |
| `p_pointer` | 33.0 million | 311 | 49.9 | 100% |  |
| `p_shift` | 73.8 million | 312 | 51.6 | 75% | SHR 8%, SHL 6%, SAR 6%, NOT 3%, NEG 3% |
| `p_ternary` | 39.4 million | 313 | 52.5 | 63% | CMOVcc 21%, MOV r, imm 4%, MOV imm 4%, SETcc 4%, NEG 4% |
| `p_loop` | 15.0 million | 318 | 56.0 | 100% |  |
| `p_sha` | 16.8 million | 320 | 61.1 | 83% | ROR 7%, ROL 6%, SHR 2%, NOT 1% |
| `p_dbl_cmp` | 37.5 million | 321 | 53.9 | 36% | SSE MOVAPS 22%, SSE COMISS/SD 11%, SSE MOVUPS/SS/SD 5%, MOV r, imm 5%, CMP A, imm 5% |
| `p_bignum` | 44.7 million | 325 | 57.2 | 91% | MUL 5%, MOV imm 3%, MOV r, imm 1% |
| `p_bitfield` | 67.6 million | 330 | 55.5 | 66% | SHL 11%, SHR 7%, SAR 5%, AND A, imm 2%, MOVSXD 2% |
| `p_index` | 29.9 million | 338 | 56.1 | 95% | SHL 2%, SHR 2%, NOP 1% |
| `p_pixel` | 26.5 million | 339 | 58.0 | 55% | IMUL 18%, SHR 14%, SHL 7%, MOV r, imm 4%, CMOVcc 2% |
| `p_muldiv` | 30.8 million | 369 | 75.1 | 73% | CDQ/CQO 7%, DIV 7%, IDIV 7%, MOVSXD 3%, IMUL 3% |
| `p_fill` | 7.8 million | 369 | 71.4 | 7% | MOVSB 47%, STOSB 39%, MOVS 2%, STOS 2%, MOV r, imm 2% |
| `p_dbl_conv` | 33.8 million | 373 | 62.6 | 36% | SSE CVTTSS/SD2SI 14%, SSE CVTSI2SS/SD 9%, SSE MUL 9%, SSE CVT ss/sd 9%, SSE PXOR 9% |
| `p_float` | 23.1 million | 379 | 62.8 | 20% | SSE MOVUPS/SS/SD 20%, SSE ADD 20%, SSE MOVAPS 7%, SSE MUL 7%, CMP A, imm 7% |
| `p_dbl_arith` | 21.6 million | 385 | 64.4 | 14% | SSE MOVUPS/SS/SD 21%, SSE ADD 21%, SSE MUL 14%, CMP A, imm 7%, SSE MOVAPS 7% |
| `p_simd` | 16.6 million | 471 | 98.1 | 9% | SSE MOVDQA/U 18%, SSE/MMX 0F F4 14%, SSE/MMX 0F 70 12%, SSE/MMX 0F 72 9%, SSE/MMX 0F 73 9% |
| `p_ldbl` | 13.9 million | 477 | 97.6 | 17% | x87 78%, CMP A, imm 6% |

- **The integer primitives are all alike: 291 to 339.** `p_if` and `p_pointer` are run
  wholly by the front and take 291 and 311; `p_ternary` has 37% of its instructions in the
  rest of the CPU (CMOV, SETcc, NEG) and takes 313, `p_shift` 25% and 312. Going through
  the rest costs about 60 host instructions more for an instruction that does (22 more
  for 37%). So a kind taken into the front is worth 60 times its share, no more: for
  shifts in `p_bitfield`, a third of its instructions, that is 20 of 330. The hypothesis
  named the indirect CALL and JMP, CMOV and the shifts as what would be expensive. They
  are not.
- **What is expensive:**
  - `p_fill`, 369 for each *repetition*: a REP MOVSB of a thousand bytes is a thousand
    instructions through the whole of `exec64`, one byte each. A copy of the same bytes
    by a loop in the CPU would be a few host instructions a byte.
  - `p_muldiv`, 369, with 14% DIV and IDIV: the division is done bit by bit.
  - The XMM registers: 373 to 385 for double and float, where four fifths of the
    instructions are SSE, and 471 for the pixels several at a time (98 cycles). Stepped
    in `p_dbl_arith`: `sse64_op` 76 and the rest of `exec64` 64 for each instruction, with
    `farith64` 25.
  - `p_ldbl`, 477: the x87, 78% of its instructions.
- **The numbers are user mode's, and its run loop costs twice the machine's**: `main` is
  61 host instructions for a guest instruction here (stepped in `p_dbl_arith`), 31 in the
  machine, whose loop E106 shortened. The primitives are compared with each other on equal
  terms, but their numbers are not to be set beside the boot's 289.
- **Six programs did nothing at first.** Their work was a function of numbers that never
  changed, called in a loop, and GCC called it once. They printed the right result and
  ran 0.1 million instructions. Each round now changes what the next works on. Seen only
  because the table has the count of guest instructions in it.
- **Held to the real CPU**: all 23 print what they print when run on the real CPU itself
  (`tools/prim64.sh`). The programs are kept built (`tests/prim64/p_*.elf`, GCC 15.2).
- **Not measured**: the primitives inside the machine, with paging (their memory accesses
  then go through the TLB); how common each primitive is in real programs (E104 has the
  boot's and three user programs' opcodes, and that is what the order below leans on).

**Next: the plan is `docs/primitives64.md`**, one entry for each group, in this order: the
string instructions with a repeat count; division; the front's missing integer kinds
(shifts, CMOV and SETcc, MOV of a constant, the indirect CALL and JMP) as one entry, worth
less than was thought; double and float; then the pixels several at a time and the x87.
Each entry is measured on its primitives and on the boot.

## E113: all the repetitions of a string instruction in one go (2026-11-20)

The first line of the plan (`docs/primitives64.md`). `p_fill` takes 369 host instructions
for every repetition of REP MOVS and REP STOS: each repetition is a whole instruction to
the run loop (found in the cache, sent to the rest of the CPU, the registers saved, one
element moved, back to the loop). That is how the real CPU looks from outside too, one
repetition for each single step, which is why it was written so.

- **Hypothesis**: **REP MOVS and REP STOS can run as many repetitions inside one call of
  `exec64` as there are instructions left before the run loop's next timed thing, with
  the instruction count and the saved start moved on after each, so that nothing outside
  can tell: the count of instructions, the time, where a fault or an interrupt falls and
  what it finds are the same. `p_fill` takes under 120 host instructions for a
  repetition (369 now), and the boot loses 3 or 4 of its 289 (1.7% of its instructions
  are repetitions).**
- **What changed since last time**: the first entry measured on a primitive. The change
  is to one function, `string_op`, and to what the run loop tells it.
- **Next move for each result**:
  - Under 120 and the boot's count of instructions unchanged → kept; then whether the
    elements can be moved a page at a time and not one by one (a second step, measured
    the same way), then the plan's second line
  - `p_fill` no better than 250 → the cost is in `rd` and `wr` for each element, not in
    the way round the loop: the page-at-a-time move comes first
  - The boot's count of instructions differs → something outside can tell: find what
    (a fault in the middle, the timer) and make a system test of it
  - A trace differs → the tracing run must stay one repetition for each step; it is
    told so by the run loop
- **Cut-off**: MOVS and STOS with a repeat count. CMPS, SCAS, LODS and the port's string
  instructions stay as they are, and so does a run with a trace, a single step or
  anything waiting.

**Result: `p_fill` takes 84 host instructions for a repetition (369 before) and 24.7
cycles (71.4); the boot 284 for an instruction (289), with its count of instructions
unchanged, 1,523,597,312. Kept.**

| | Host instructions for each | Cycles for each |
|---|---:|---:|
| `p_fill`, before | 369 | 71.4 |
| … the repetitions in one call, an element at a time through `rd` and `wr` | 159 | 36.7 |
| … a stretch that stays on its pages moved in memory | 84 | 24.7 |
| The boot, before | 289 (440 thousand million) | 76.6 to 76.8 thousand million |
| The boot, after | 284 (432) | 75.7 to 76.1 |

- **The first step was the card's middle (159, predicted under 120)**, so the second
  followed at once: the pages are found once for a stretch that stays on them at both
  ends, and the bytes are moved in the memory array. What is left of the 84 is mostly
  not the repetitions: `p_fill` has 160,000 short string instructions (13 and 5 bytes),
  each of which is an instruction through the rest of the CPU before its first byte
  moves, and the loop round them.
- **Nothing outside can tell**, and that is checked three ways. The boot runs the same
  number of instructions to its prompt. A run with a trace does one repetition for each
  step as before (the 19 traces from the real CPU). And a fault in the middle finds RCX,
  RSI and RDI as the repetitions before it left them: the start saved for a fault is
  moved on after every stretch.
- **One case is not as before, and is not tested**: a REP STOS or MOVS that writes over
  its own bytes went on, before, as whatever the new bytes said from the next repetition;
  now it finishes the stretch first.
- **When a stretch is not moved in memory**: going down (DF set); an element that lies
  across a page's end; a destination page that holds remembered code, or is not plain
  memory; a source that begins less than one element below the destination, where a byte
  at a time is not an element at a time. Those go an element at a time as before.
- **Held to the real CPU.** A new system test, `y_string` (64 lines from KVM): fills and
  copies of each width over several pages beginning anywhere, the source one byte, three
  bytes, one element below the destination and above it, going down, addresses and a
  count of 32 bits, a source in FS's segment, a fill and a copy that meet a page that is
  not there (the handler prints what it found and maps the page), an element across the
  end of the last page that is there, and a copy over code that has run. It passed at
  its first run. 19 programs, 9 system tests, the 23 primitives and the kernel's four
  boots pass.
- **Wrong builds: 18 of 18 caught**, 17 at first; the one that passed (FS's base left out
  of the source of a stretch) had no test, and has the case above now. Three of them
  (the count of instructions not moved on, moved on by one too many, a stretch past the
  run loop's limit) are caught only by the boot's count of instructions, which the
  script now checks for them.
- **A line added to the run loop cost every other primitive 6 host instructions** (the
  limit was set before each instruction in user mode). Seen in the table for `p_bytes`
  and `p_pointer`, which have no string instruction; it is set once now.

**Next.** The plan's second line: division. And for the string instructions, what is left
is the first repetition's way through the rest of the CPU (a short REP is an instruction
like any other); that belongs to the plan's third line.

## E114: division of 64 bits without the loop when the upper half is empty (2026-11-20)

The plan's second line. `p_muldiv` takes 369 host instructions for a guest instruction,
and 14% of its instructions are DIV and IDIV. A division whose operand is 64 bits wide
divides the 128 bits of RDX:RAX, and `div128` does that one bit at a time, 64 times
round, whatever the numbers are. Narrower divisions are one division of the host's
already.

- **Hypothesis**: **nearly every 64-bit division a compiler makes has an upper half that
  holds nothing (RDX cleared for DIV; for IDIV, RDX filled with RAX's sign by CQO, which
  is nothing once the sign is taken off). With that case one division of the host's,
  `p_muldiv` takes under 345 host instructions for each (369 now). The boot does not
  change: it hardly divides.**
- **What changed since last time**: nothing in the way instructions are run; one function,
  `div128`, gets a short way in front of the loop it has.
- **Next move for each result**:
  - Under 345 → kept; what is left in `p_muldiv` is the rest of the CPU's instructions in
    it (CQO, MOVSXD, IMUL), which is the plan's third line
  - Little change → the divisions are not what makes it 369, or its 64-bit ones are a
    small part: step one division and see what it runs
  - A test differs → the short way is taken when it may not be (the quotient must fit:
    the caller has checked that the upper half is less than the divisor)
- **Cut-off**: `div128`'s entry. The loop stays for a dividend of more than 64 bits.

**Result: `p_muldiv` takes 311 host instructions for a guest instruction (369 before) and
51.6 cycles (75.1): among the other integer primitives now. The boot is unchanged (284,
the same count of instructions). Kept.**

- One division of the host's where `div128`'s upper half is empty; the loop of 64 rounds
  stays for the rest. `p_bignum`, which multiplies and does not divide, is unchanged
  (325).
- **Held to the real CPU.** 20 programs (one new), 9 system tests, the 23 primitives, the
  kernel's four boots.
- **Wrong builds: 4 of 4 caught**, 3 at first. The one that passed took the short way
  when the upper half held one: no test divided such a number (the generated tests'
  upper halves are large, the C programs' are empty). New: `a_div`, 87 traced
  instructions from the real CPU: upper halves of nothing, one, two and one less than the
  divisor, and for IDIV each with each sign.

**Next.** The plan's third line, the widest: the integer instructions the front does not
run. With division out of the way `p_muldiv`'s 311 against `p_if`'s 291 is that line
(CQO, MOVSXD, IMUL: 27% of its instructions go to the rest of the CPU).

## E115: a program built on the real machine, run as it is: NetHack (2026-11-20)

The owner's aim: what is built on the real x86_64 machine (the oracle's host, an Ivy
Bridge) runs on g86m as it is. The primitives were written for g86m; NetHack 3.6.7 was
not: 110 files of C from 1987 onward, a curses library, a terminal driven by escape
sequences, files read and written.

- **Hypothesis**: **NetHack built on the real machine with its GCC, linked statically,
  runs in g86m's Linux guest from a disk, to the first level drawn and the inventory
  opened, with no change to g86m.**
- **What changed since last time**: nothing in `src/`. The disk's script takes a
  directory to add to the root.
- **Next move for each result**:
  - It runs → kept as a system test; then the same NetHack built inside the guest, by
    the guest's own GCC, which is a long real program to count instructions in
  - It stops on an instruction not written → that instruction, with a test from the
    real CPU, before anything else
  - It runs wrong (a screen that is not NetHack's) → the first wrong byte found by
    running the same keys on the real machine
- **Cut-off**: the keys of a first minute (a character taken, the level, the
  inventory). Not a game played.

**Result: it runs, with no change to g86m.** 1,933 million instructions from the kernel's
entry to the inventory on the screen; the level is drawn, the pet beside the player, the
status lines under it.

- **Two things stopped it first, and neither was g86m's**: both are what a statically
  linked program still takes from the system it runs on, and the disk had neither.
  "Unknown terminal type: xterm": the curses library reads the terminal's description
  from a file. Then a fault at address 0 after the banner: the user's entry in
  `/etc/passwd` is asked for and what comes back is used unlooked-at. The disk has four
  terminal descriptions and a `passwd` now.
- **Not compared with the real machine key for key.** The character is drawn by lot from
  the time, so two runs differ; what the test checks is that the first level and the
  inventory come up.
- `tools/images/make-nethack.sh` builds it on the host named and makes
  `images/disk64-nh.img`; `tools/systest64.sh` runs it when the image is there. Neither
  NetHack nor the image is in the repository.

**Next.** NetHack built inside the guest, with the instructions counted while it builds.

## E116: a JIT for the 64-bit CPU: what it is to be (a survey; 2026-11-20)

NetHack built by the guest's own GCC takes the real machine 71 seconds and g86m more than
half an hour. g86m runs 62 million guest instructions a second; the plan in
`docs/primitives64.md` takes host instructions off the 284 each costs, a few tens at a
time, and all of it together is a factor of two at best. The 32-bit machine's JIT took its
Linux boot from 88 host instructions for a guest instruction to 22 (E073). The owner's
decision: the JIT comes first, and the plan's other lines wait behind it.

This entry builds nothing. It reads the 32-bit JIT (`docs/jit.md`, `src/jit.goose`, 1,659
lines) for what carries over, counts what the 64-bit guest's code looks like to a
translator, and writes the design down.

- **Hypothesis**: **the 32-bit JIT's design carries over whole (blocks found through the
  decode cache, guest registers in host registers, the flags as a record, memory by the
  TLB inline with a way out, links inside a page and a far way between pages), and what
  is new for 64 bits is small: sixteen registers, operands of 64 bits, addresses relative
  to RIP. Counted over the boot, nine tenths of the instructions lie in runs of two or
  more instructions of the short front's kinds that end at a jump, which is what a
  first translator could take.**
- **What changed since last time**: the direction. No entry before this was about
  translating.
- **Next move for each result**:
  - Nine tenths or more → the first translator takes the front's kinds as they are: the
    first step is a block of them without memory operands, run from the front
    (`p_loop`), then memory, then links
  - Between a half and nine tenths → the instructions that cut the runs short are
    counted, and the commonest become kinds before the translator is begun (this is the
    plan's third line, done for another reason)
  - Under a half → the runs are too short for blocks as the 32-bit JIT makes them: look
    at what ends them (jumps every few instructions) and whether a block may go on
    through a jump not taken
  - Something in the 64-bit machine that the 32-bit design cannot hold → named, with
    what would hold it, before anything is built
- **Cut-off**: the count over the boot and one user program; the design as a document
  (`docs/jit64.md`). No generated code.

**Result: the design carries over, and the design is written (`docs/jit64.md`); the count
is the card's middle branch. 79% of the boot's instructions lie in runs of two or more of
the front's kinds, not nine tenths, and the runs are under four instructions long.**

| The boot, 1,524 million instructions | Share | Runs | Mean length |
|---|---:|---:|---:|
| In a run of two or more that ends at a jump | 53.3% | 220 million | 3.7 |
| In a run of two or more that ends at an instruction of no kind | 25.4% | 92 million | 4.2 |
| Of a kind, alone | 5.9% | | |
| Of no kind | 13.7% | | |

- **What cuts the runs is a short list**: shifts and rotations 5.8% of all instructions,
  the group `F6`/`F7` 2.5%, NOP 1.8%, MOV of a constant 1.3%, MOVSXD 0.7%, ENDBR64 0.5%.
  With those and a few more the kinds cover 97%. They are the plan's third line
  ("the front's missing integer kinds"), which E112 found worth little to the
  interpreter (60 host instructions each): to a translator each one ends a block, so
  they are its first task.
- **What the 32-bit design cannot hold as it is, and what holds it**: RIP is not a
  constant in a block, since a block is found by its physical address and a page of a
  shared library is at another virtual address in each program: the page's virtual base
  is kept in a register. And sixteen guest registers with everything else come to 28
  host registers, all there are.
- **Not counted**: a user program. The boot is 99.8% the kernel. NetHack's build in the
  guest is counting as this is written; its numbers go into `docs/jit64.md` when it
  ends.

**Next.** The JIT's first task (`docs/jit64.md`): the kinds that cut the runs, in the
short front, each tested as interpreted; then the count again.

## E117: where QEMU is (a measurement; 2026-11-20)

The owner's aim, from today: to get past QEMU, and to see how near an old technique,
written in a language an AI made, built by an AI, can come. QEMU's user-mode emulator is
what Docker hands an x86_64 program to on an arm64 host that is not a Mac, which is the
place M11 means g86m to take. So its speed is the number to be measured against, on the
same host and the same programs.

- **Hypothesis**: **on this host QEMU runs the integer primitives some tens of times
  faster than g86m (62 million guest instructions a second), and floating point by less,
  since it computes that in software.**
- **What changed since last time**: g86m's numbers have been compared only with its own.
- **Next move for each result**:
  - Tens of times on integers, less on floating point → the JIT's order stands (integers
    first), and each of its steps is reported as a distance from QEMU on these programs
  - Hundreds of times → QEMU's translation is far better than the 32-bit JIT's was, and
    the design is to be read against QEMU's before it is built
  - Under ten → the interpreter is nearer than thought; measure longer programs before
    believing it
- **Cut-off**: the 23 primitives, run twenty times each in a container (Alpine for arm64
  with its package `qemu-x86_64`), and three times on g86m. No longer programs, no system
  emulation.

**Result: 6 to 200 times on the integer primitives, 6 to 14 on double and float, 3 on
long double, and level on filling and copying.** Million guest instructions a second,
Apple M1, each program's count of instructions (E112) over the time of a run; g86m's
time less the 0.09 s it takes to start (it clears 256 MB and the decode cache):

| Primitive | QEMU 11.0.3 | Docker's own | g86m | g86m behind QEMU |
|---|---:|---:|---:|---:|
| `p_shift` | 8,200 | 11,354 | 42 | 195 times |
| `p_bitfield` | 5,878 | 7,511 | 38 | 155 times |
| `p_ternary` | 4,925 | 7,164 | 43 | 115 times |
| `p_pixel` | 4,077 | 5,889 | 40 | 102 times |
| `p_sha` | 2,800 | 4,800 | 42 | 67 times |
| `p_bytes` | 2,768 | 5,767 | 44 | 62 times |
| `p_rotate` | 2,594 | 3,978 | 47 | 56 times |
| `p_index` | 1,993 | 6,644 | 41 | 48 times |
| `p_bignum` | 1,596 | 4,257 | 35 | 45 times |
| `p_loop` | 2,000 | 5,000 | 45 | 44 times |
| `p_pointer` | 2,000 | 5,077 | 47 | 43 times |
| `p_simd` | 851 | 4,150 | 24 | 36 times |
| `p_if` | 1,394 | 3,538 | 45 | 31 times |
| `p_recursion` | 841 | 1,743 | 46 | 18 times |
| `p_muldiv` | 832 | 4,400 | 46 | 18 times |
| `p_dbl_cmp` | 620 | 5,357 | 43 | 14 times |
| `p_switch` | 511 | 1,290 | 40 | 13 times |
| `p_dbl_arith` | 369 | 1,394 | 37 | 10 times |
| `p_float` | 376 | 1,650 | 37 | 10 times |
| `p_funcptr` | 292 | 1,020 | 46 | 6 times |
| `p_dbl_conv` | 207 | 5,200 | 37 | 6 times |
| `p_ldbl` | 74 | 35 | 26 | 3 times |
| `p_fill` | 339 | 1,560 | 277 | 1.2 times |

"Docker's own" is what Docker on this host runs an x86_64 program with when nothing is
said (the same program started in the arm64 container without `qemu-x86_64` in front);
by its speed and by `p_ldbl` it is Rosetta.

- **QEMU is not one number.** Straight-line integer code runs at 2,000 to 8,000 million
  instructions a second; where the program jumps through a register (`p_funcptr`,
  `p_switch`, and every return in `p_recursion`) it falls to 300 to 800, because each
  such jump is looked up; double and float are 200 to 600, the x87 74. g86m is 24 to 47
  for everything but the string instructions: it pays the same for every instruction.
- **Where g86m is already level**: `p_fill`, 272 against 339, since E113 moves a
  stretch in memory. And on `p_ldbl` it is within three of QEMU, and of Rosetta, which
  is slower than QEMU there.
- **What it says for the JIT**: to pass QEMU on straight-line integer code a guest
  instruction must cost about two host instructions; the 32-bit JIT's boot cost 22, with
  the interpreter's share and the TLB in it. On jumps through a register and on floating
  point QEMU is five to twenty times slower than its best, and that is where a
  translator that keeps the guest's registers in the host's, links what it can and uses
  the host's floating point has the most room.
- **How rough it is**: a run under QEMU takes 6 to 190 ms, its start included, read on a
  clock of 10 ms over twenty runs; the short ones are good to a fifth at best. g86m was
  timed while another g86m was using one core. Longer programs are for a later entry.
- `tools/prim64_qemu.sh` does the measurement.

## E118: the kinds that cut the runs (the JIT's first task; 2026-11-20)

E116 counted the boot: 86% of its instructions are of the short front's kinds, and a
quarter of them lie in runs that an instruction of no kind cuts short. The list of what
cuts is short. This entry gives those instructions kinds, in the front, as interpreted
instructions: one implementation each, the rest of the CPU losing its arms for them. It
generates no code. (The guest's NetHack build of E115 is still counting on another core
as this is done, so nothing here is timed: host instructions and counts only.)

- **Hypothesis**: **with kinds for the shifts and rotations (`C0`/`C1`, `D0` to `D3`),
  the groups `F6`/`F7` and `FE`/`FF`, NOP (`90`, `0F 18` to `1F`, which is ENDBR64 too),
  MOVSXD, MOV of a constant (`B0` to `BF`, `C6`/`C7`), the ALU and TEST forms on the A
  register with a constant, and CMOVcc, 96% or more of the boot's instructions are of a
  kind, three quarters or more lie in runs of two or more that end at a jump, and such a
  run is five instructions or longer in the mean. None of them changes a register before
  the last point it can fault at, so none needs the save of the registers.**
- **What changed since last time**: E110 chose its kinds by how often they run, for the
  interpreter's sake. These are chosen by what ends a run.
- **Next move for each result**:
  - 96% of a kind and three quarters in runs to a jump → the JIT's second task: the
    arm64 emitter and blocks without memory operands
  - Of a kind, but the runs still cut → what cuts them now is counted, and the next few
    become kinds the same way (once more; after that the translator takes the runs as
    they are)
  - The boot costs more host instructions for a guest instruction than 284 → the jump
    on the kind has got worse with the kinds added: its listing is read before anything
    else is built on it
  - A wrong build of a new arm passes every test → a test for it, against the real CPU,
    first
- **Cut-off**: one count of the boot's runs; the three suites; wrong builds of each new
  arm.

**Result: the hypothesis holds on all three counts. 99.75% of the boot's instructions are
of a kind, 96.1% lie in runs of two or more that end at a jump, and such a run is 5.8
instructions in the mean. The boot costs 275.6 host instructions for a guest instruction
(E113: 284).**

| The boot, 1,524 million instructions | E116 | Now |
|---|---:|---:|
| Of a kind | 86.3% | 99.75% |
| In a run of two or more that ends at a jump | 53.3%, mean 3.7 | 96.1%, mean 5.8 |
| In a run of two or more that an instruction of no kind cuts | 25.4% | 0.8% |
| Host instructions for a guest instruction | 284 | 275.6 |

- **Two rounds, as the card allows.** The first was the card's list. After it the boot
  was at 99.6%, but the primitives showed what still cut a user program's runs: SETcc
  (7% of `p_bytes`), IMUL with two or three operands (18% of `p_pixel`), MOVSX, CDQ and
  its family (7% of `p_muldiv`). The second round gave those kinds, and PUSH of a
  constant. Every integer primitive now runs in the front whole; what the front leaves
  is the SSE, the x87, BSF and BSR, and the string instructions.
- **None of them needs the save of the registers**, and that was read off the code, one
  by one, before it was moved: MUL and DIV change RAX and RDX after the last fault they
  can raise; CALL through an operand reads the operand and then pushes; LEAVE was left
  out because it changes RSP and then reads.
- **One implementation of each**: the rest of the CPU lost its arms for all of them.
  (92 lines out of `cpu64.goose`, 135 in.)
- **Wrong builds: 45 of 46 caught, after two tests were added.** Of the first 28, two
  passed: a JMP through a register that took 32 bits of the address (no test jumped
  above 4 GB except by RET), and a CALL through memory that pushed before it read. For
  the first, `y_tlb` now jumps and calls through a register and through memory to code
  above 4 GB. For the second, a new trace test `a_call`: CALL, JMP and PUSH of operands
  found from RSP, among them a CALL through the very place the return address goes to
  (a first version of the test, without that one, did not catch it: the operand's
  address is worked out before anything is pushed, so only the read's place in the
  order shows). The one left, PUSH of an operand read after RSP has moved, changes
  nothing that can be seen, for the same reason.
- **The primitives** moved little, as E112 said they would (60 host instructions for an
  instruction that goes to the rest): `p_shift` 312 → 303, `p_pixel` 339 → 312,
  `p_muldiv` 311 → 297, `p_bytes` 309 → 302; `p_loop`, `p_if` and `p_switch` are within
  3 of where they were. The table in `docs/primitives64.md` is the new one.
- **Not timed.** The guest's NetHack build held a core through most of this, and when
  it ended the host was busy with something of its own (a boot took 38 s for the same
  74 billion cycles: it ran on the slow cores). The times, and the comparison with QEMU
  again (E117's g86m column was taken under the same load), wait for a quiet host.
- **Found and not fixed**: an instruction that begins with `0F` takes its kind from the
  byte after, and when that byte is the first of the next page the kind is remembered
  with the first page's entries: a write to the second page does not drop it. It has
  been so since E110, nothing here widens it (the groups look at their field each time
  they run), and no test reaches it.

**Next.** The JIT's second task (`docs/jit64.md`): the arm64 emitter and a block of
instructions without memory operands. And the `0F` entry across two pages, with a test.

## E119: NetHack built in the guest, counted (E115's next step; 2026-11-20)

This was started as the last line of E115 says, without a card of its own, before E116
and E118: recorded here as what was seen. A disk of 640 MB with Alpine 3.24's GCC 15.2,
make, musl and ncurses and NetHack's source; `make all` in the guest, under a copy of
g86m that counts (the build of E113, with the kinds of E110).

**Result: the build stopped at the last file but four, and not because of g86m. The
count is whole enough to use: 428 billion guest instructions, 80% of them in user mode,
85.0% run by the short front as it was; with E118's kinds it would be 96.3%.**

- **What stopped it**: `sys/share/unixtty.c` includes `linux/vt.h`, and the disk has no
  kernel headers (the package `linux-headers`). The image was made without it. Every
  file of `src/` before that compiled, the compiler's exit codes clean: about 125 runs
  of `cc1`, `as` and `make` with no instruction not written and no fault that was not
  the program's own. What they wrote was not checked: nothing was linked or run.
- **How long**: 4 h 29 min under the counting copy, on a host doing other work, which
  is not a time. At the 62 million instructions a second the plain build runs at, 428
  billion are 115 minutes, for a part of the build that takes the real machine a little
  over a minute: about a hundred times slower, as E116 guessed.
- **What a compiler's instructions are** (share of all 428 billion):

  | | Share |
  |---|---:|
  | In user mode | 80.3% |
  | Run by the front (E110's kinds) | 85.0% |
  | Would be, with E118's kinds | 96.3% |
  | … of which: `C1` shifts 1.6%, NOP and ENDBR64 1.4%, the A register and a constant 1.4%, MOV of a constant 2.3%, `F6`/`F7` 1.1%, MOVSXD 0.6%, `D3`/`D1` 0.6%, `FF` 0.5%, SETcc and CMOV 0.8%, IMUL 0.3% | 11.2% |
  | SSE, nearly all of it moves (`0F 6F`, `0F 11`, `0F 29`, `0F 6E`, `0F 7E`) and PXOR/POR: GCC copying and clearing structures | about 2% |
  | Repetitions of string instructions | about 1% |
  | BT | 0.2% |

  MOV is 26% of everything, the short Jcc 8.5%, ALU with ModRM 10%, the group
  80h/81h/83h 10%. A fifth of the time is the kernel's (page faults, files, `fork` and
  `exec` for each of the 125 compilations).
- **For the JIT**: a compiler looks like the boot to a translator once E118's kinds are
  there. The first thing it adds to the list is the SSE's moves, which task 8 (scalar
  SSE) did not have in view: they are there in integer code.

**Next.** `linux-headers` on the disk (a download, for the owner to allow), and `make`
again from where it stopped, under the plain build on a quiet host: the objects are on
the disk, so it is the last few files, the link and the install. Then the NetHack it
built, run.

## E120: the first generated code: blocks of instructions that touch no memory (the JIT's second task; 2026-11-20)

E118 left 96% of the boot's instructions in runs of the front's kinds. This entry
translates the part of such a run that needs nothing from memory: an emitter for arm64
(`src/jit64.goose`), a way in and out, and blocks made of register-only instructions
with operands of 32 and 64 bits, entered from the short front by one more kind. No
links between blocks, no memory operands, no stack: those are tasks 4 to 6. The flags
are a record of the last flag-setting instruction's operands, settled after the block
by the interpreter's own functions (task 3 makes it cheaper).

- **Hypothesis**: **generated code for register-only runs, entered and left through C
  for every block, already takes the primitives that are loops over registers
  (`p_loop`, `p_if`, `p_shift`) from about 300 host instructions for a guest instruction
  to under 100; and with every block run both ways and compared (`--jit-check`: the
  block, then the same instructions interpreted from the same state), every suite
  passes.**
- **What changed since last time**: the first generated code on the 64-bit CPU.
  Everything up to E118 was the interpreter.
- **Next move for each result**:
  - Under 100 on those three → task 4, memory operands for a program without a kernel,
    which is what makes blocks as long as the runs
  - 100 to 200 → the way in and out is what is left: counted, and links (task 6) come
    before memory
  - No gain to speak of → how many instructions ran in blocks is read: if few, the
    blocks are too short without memory operands and task 4 comes at once; if many,
    the listing of one block is read
  - `--jit-check` finds a difference → that instruction's translation, with the test
    that shows it, before anything else
- **Cut-off**: the three primitives' host instructions; the suites with `--jit` and
  with `--jit-check`; wrong builds of the translator. The comparison with QEMU when the
  host is quiet.

**Result: generated code runs, and every block agrees with the interpreter; the
hypothesis's number holds for one of its three primitives. `p_shift` 309 → 27 host
instructions for a guest instruction, `p_loop` 326 → 102, `p_if` 301 → 233. The boot:
276 → 201, with 49% of its instructions run in blocks.** (Whole runs, the program's
start included, so a little above the table's figures.)

| | Host instructions for a guest instruction, interpreted | With `--jit` | Instructions run in blocks | Instructions for each entry into a block |
|---|---:|---:|---:|---:|
| `p_shift` | 309 | 27 | 97% | 34.9 |
| `p_ternary` | 297 | 40 | 96% | 22.9 |
| `p_pixel` | 318 | 79 | 89% | 10.0 |
| `p_bitfield` | 321 | 99 | 82% | 9.0 |
| `p_loop` | 326 | 102 | 100% | 5.0 |
| `p_muldiv` | 303 | 136 | 80% | 4.8 |
| `p_sha` | 320 | 145 | 76% | 6.4 |
| `p_switch` | 296 | 218 | 65% | 2.5 |
| `p_if` | 301 | 233 | 64% | 2.3 |
| `p_pointer` | 321 | 247 | 50% | 2.7 |
| `p_funcptr` | 306 | 252 | 44% | 2.7 |
| `p_dbl_arith` | 399 | 403 | 0% |  |
| The boot | 276 | 201 | 49% | 3.5 |

- **What a block costs is the way in and out, not its instructions.** Stepped one host
  instruction at a time through a shell's loop in the guest: an entry into a block is
  300 to 500 host instructions, in many small parts and no large one: the front's
  beginning and the rest of the CPU's (where a block's first instruction is found), 88
  in `jit_enter` itself, the sixteen registers loaded and stored, the flags settled by
  `alu` (60), the run loop. A block's own instructions are a few each. So the figure
  for a primitive is nearly 400 divided by how many instructions it runs for each
  entry: 23 in `p_ternary`, 2.3 in `p_if`.
- **The card's middle branch, then, with its order confirmed by the count**: what is
  left is the entries. Two things take them away, and both were in the plan: memory
  operands (tasks 4 and 5), which make a block as long as the run (the boot's blocks
  are 3.2 instructions for runs of 5.8, and a program's that uses the stack are 2 to
  3), and links (task 6), which take a block to the next without the way out and in.
- **How it is built.** A block's first instruction is kept in the decode cache without
  a kind, so it goes to the rest of the CPU, which looks whether a block begins there:
  the front's path has nothing of the JIT in it (Goose refuses a function that reaches
  itself, and the front's jump on the kind could not take one more arm that goes back
  to the front). Arrivals are counted where a jump lands and where a page is entered;
  at the eighth, the page is translated from there on, block after block, as far as
  the decode cache knows the instructions.
- **The flags** are not made in generated code. The block leaves the last
  flag-setting instruction's operands and what it was, and the interpreter's own `alu`,
  `shift`, `incdec` or `imul2` is called on them: right by construction. A jump on a
  condition right after a CMP, SUB, ADD, AND, OR, XOR or TEST in the same block uses
  the host's flags; one with no flag-setting instruction before it in the block tests
  RFLAGS in memory; anything else ends the block before it. INC and DEC leave CF as it
  was, and are translated only as the first to set flags in their block. A shift by CL
  may be by zero, which changes no flag: the record is replaced only if the count is
  not zero.
- **`--jit-check`** runs every block and then, from the same state, the same
  instructions interpreted, and compares the registers, RFLAGS and RIP. It is what
  the suites are run with: the 23 primitives, the 9 system tests and the six Linux
  checks (the boot to the shell, the disk, NetHack, the network, the frame buffer)
  pass with it and with `--jit`. The trace tests print every instruction and so run
  no block: they say nothing about the JIT.
- **The globals' order cost the interpreter 27 host instructions for each guest
  instruction, and was put right.** The first build ran the boot without `--jit` at 303
  where E118 had 276: the four arrays the JIT keeps beside the decode cache (1.8 MB)
  had come in front of the CPU's own state among the globals, and every use of a
  register, RIP or the flags was two host instructions longer (E110 found the same
  rule). They are declared behind the guest's memory now, in `cpu64.goose`, and the
  boot without `--jit` is 276 again (420.1 billion). The numbers above are after that.
- **Wrong builds of the translator: 48 of 49 caught, after the tests were made to reach
  it.** Of 50 prepared, 29 were caught by the primitives and the system tests under
  `--jit-check` and `--jit`. The 21 that passed said three things. The tests had no
  short run of register-only instructions made hot on purpose: `j_blocks` is one (jumps
  on every regime of the host's flags and on RFLAGS in memory, 32-bit results whose
  upper half must go, the flags one block leaves for the next), and `j_slot` has two
  instructions that share an entry of the decode cache, the first a block's head. A
  trace test said nothing about the JIT: `tools/difftest64.sh` now runs every program
  once more with `--jit-check`. Nothing compared the count of instructions with and
  without the JIT (a block that counts itself one too many, or runs past the time the
  run loop gave it): `tools/prim64.sh` and the Linux boot in `tools/systest64.sh` do,
  when given options. One wrong build was no wrong build: a shift by CL translated
  after another flag-setting instruction is right, because its record is conditional,
  and the rule that forbade it was taken out (`p_shift` went from 60 to 27 by it). The
  one not held: RF cleared at a block's first instruction; no test resumes with RF set
  at a block's head.
- **Against QEMU, roughly**: the host was not quiet (load 4.7) and the programs run a
  tenth of a second, most of it start-up. `p_shift` about 1,200 million guest
  instructions a second (E117: g86m 42, QEMU 8,200), `p_loop` about 360 (45; 2,000).
  From 200 and 44 times slower than QEMU to something like 7 and 6. To be taken again
  with `tools/prim64_qemu.sh` on a quiet host, with longer programs.

**Next.** Task 4, memory operands for a program without a kernel, then 5 (the TLB, the
stack) and 6 (links): in that order by the count above. Before them, the time against
QEMU on a quiet host.

## E121: memory operands and the stack, for a program without a kernel (the JIT's fourth task; 2026-11-20)

E120's blocks end at every instruction that touches memory: 2 to 3 instructions an entry
in a program that uses the stack, and an entry costs 300 to 500 host instructions. In a
program run without a kernel a guest address is an index into the memory array, so a
load or a store is one host instruction and two checks. This entry translates them:
MOV, the ALU instructions, MOVZX and MOVSX, CMOV and IMUL with an operand in memory;
PUSH, POP, CALL and RET; CALL and JMP through an operand. In a machine (a kernel booted)
they still end the block: that is task 5, the TLB.

- **Hypothesis**: **with loads, stores and the stack in the blocks, the primitives that
  were at 220 to 260 host instructions for a guest instruction (`p_if`, `p_switch`,
  `p_pointer`, `p_funcptr`, `p_recursion`, `p_index`, `p_bytes`, `p_bignum`) run more
  than nine tenths of their instructions in blocks, 5 or more for each entry, and come
  under 100.**
- **What changed since last time**: a block can now leave before its end (an address
  outside memory, a store into a page that holds remembered instructions), so a block
  gives back how many instructions it ran; and `--jit-check` has to take back what a
  block stored before the same instructions are interpreted.
- **Next move for each result**:
  - Under 100 → links (task 6) for programs without a kernel, since every entry that is
    left is a jump; measured against QEMU on a quiet host first
  - In blocks, but still over 100 → the entry's cost is counted part by part and the
    cheap parts taken (the registers not loaded and stored each time, the flags'
    record settled only when read)
  - Not in blocks → what still ends them is counted and translated (byte operations,
    the string instructions, SSE moves)
  - `--jit-check` finds a difference → that translation, with a test, first
- **Cut-off**: those eight primitives; the suites with `--jit` and `--jit-check`; wrong
  builds.

**Result: the instructions are in the blocks now, and the hypothesis's number holds for
two of its eight primitives. `p_index` 247 → 79 host instructions for a guest
instruction and `p_pointer` 247 → 92; the other six are between 129 and 203, because a
block still ends at every jump and they jump every two to five instructions.**

| | Interpreted | E120 | Now | In blocks | Instructions for each entry |
|---|---:|---:|---:|---:|---:|
| `p_index` | 348 | 247 | 79 | 97% | 8.1 |
| `p_pointer` | 324 | 247 | 92 | 100% | 5.3 |
| `p_recursion` | 314 | 232 | 129 | 100% | 4.2 |
| `p_funcptr` | 309 | 252 | 167 | 96% | 2.8 |
| `p_bignum` | 333 | 253 | 192 | 64% | 5.0 |
| `p_if` | 304 | 233 | 192 | 100% | 2.3 |
| `p_switch` | 299 | 218 | 193 | 86% | 2.5 |
| `p_bytes` | 311 | 227 | 203 | 57% | 4.0 |
| `p_loop` | 328 | 102 | 107 | 100% | 5.0 |
| `p_shift` | 312 | 27 | 20 | 100% | 35.9 |
| `p_ternary` | 299 | 40 | 28 | 100% | 24.0 |
| `p_pixel` | 322 | 79 | 54 | 96% | 14.9 |
| `p_sha` | 323 | 145 | 121 | 83% | 7.8 |

(The first eight are the card's; the rest are there to show nothing was lost. Whole
runs, the program's start included.)

- **In blocks: yes.** Six of the eight run 96% or more of their instructions in blocks
  (`p_bytes` 57% and `p_bignum` 64% are held back by byte operations and by ADC and SBB,
  which are not translated yet).
- **Five or more for each entry: no, and that is the whole of what is left.** `p_if`
  runs every instruction in a block and still costs 192, because it enters a block for
  every 2.3 instructions: 192 × 2.3 is the 440 host instructions an entry costs. A run
  between two jumps is that short in a program that is mostly branches, and no kind of
  operand changes it. Only a block that goes on into the next without leaving does:
  links (task 6). So the card's first and second branches both: links next, for a
  program without a kernel first, and the entry's own cost while at it.
- **How a block leaves before its end.** Each load and store checks its address (eight
  bytes from it inside memory; for a store, neither page holding remembered
  instructions) with instructions that leave the host's flags alone, before anything is
  changed, and branches to a way out behind the block that gives the address of that
  instruction and how many were run before it. A block left before its first
  instruction runs nothing, and the interpreter runs the instruction.
- **`--jit-check` with stores**: a block translated under it logs each store's address
  and the eight bytes that were there; after the block, what it left is kept, the
  stores are taken back last first, and the same instructions are interpreted and
  compared, memory included.
- **Arrivals were not counted after a block** (a block's exit is a jump the front never
  sees), so under `--jit` less was translated than under `--jit-check`: `p_if` ran 79%
  in blocks one way and 100% the other. They are counted now.
- **Not timed**: the wrong builds were running.
- **Wrong builds of the memory translation: 29 of 33 caught, after a test was written
  for them.** 16 were caught at first. `j_mem` (a trace test, expected from the real
  CPU) has what the rest needed: operations that are not the same both ways round (SUB
  and CMP with the operand in memory on either side), a displacement below the base,
  constants that must be sign-extended, one byte loaded into a register, POP into RSP,
  CMOV from memory, and stores into a page of instructions from a block that is already
  translated, one as the block's first instruction and one in its middle. That last
  took three attempts: stores made by the interpreter before the blocks are translated
  make the page given up, so the stores go to data until the blocks are there; and
  `--jit-check` interprets every store again, which puts the decode cache right behind
  a wrong block, so the test ends with an exit code that a run with `--jit` alone is
  held by (`tools/difftest64.sh` runs each program that way too). Of the four left,
  three change nothing a program can see: a displacement cut to 32 bits is caught by
  the bounds check and interpreted (slower, not wrong), where translating goes on
  behind a CALL through an operand, and a 64-bit load for MOVSXD. One is not held: a
  load or store with no check that it is inside memory. Nothing in the tests reaches
  outside memory, and a real CPU has no such edge to compare with.

**Next.** Links between blocks (task 6), for a program without a kernel first; and the
time against QEMU on a quiet host.

## E122: links between blocks, for a program without a kernel (the JIT's sixth task; 2026-11-20)

E121 left every instruction of `p_if` in a block and the program at 192 host
instructions for a guest instruction: it enters a block for every 2.3 instructions, and
an entry costs 440. A block that ends at a jump to a known address can go on into the
block there without leaving generated code.

- **Hypothesis**: **with a block's static exits (both sides of a Jcc, JMP, CALL, the
  instruction after a block's end) branching straight into the block at the target, the
  primitives that are all in blocks (`p_if`, `p_loop`, `p_pointer`, `p_recursion`,
  `p_shift`, `p_ternary`, `p_index`) run 50 or more instructions for each entry from
  the interpreter and come under 30 host instructions for a guest instruction; what
  stays above is what leaves by a jump through an operand or a RET (`p_funcptr`,
  `p_switch`).**
- **What changed since last time**: generated code runs more than one block at a time.
  The time a run may take is counted down in a register and tested where a block is
  entered from another; the flags' record crosses from block to block, so a block that
  reads RFLAGS in memory is entered from another only when no record is waiting; a
  write to a page that holds blocks drops every block.
- **Next move for each result**:
  - Under 30 → the time against QEMU on a quiet host, then what the listing of a block
    says is wasted (the record made for flags nothing reads, constants built in four
    instructions)
  - Linked, but over 30 → the listing of the commonest blocks is read for what each
    instruction costs
  - RET and jumps through an operand hold the rest back → a look-up of the target in
    generated code (the far way)
  - A run with `--jit` differs from a run without → the link that did it, found by
    turning links off (`--jit-off` bit 63), with a test
- **Cut-off**: those primitives; the suites; wrong builds of the linking.

**Result: the hypothesis holds for five of its seven primitives. `p_if` 192 → 23 host
instructions for a guest instruction, `p_loop` 107 → 28, `p_pointer` 92 → 18,
`p_ternary` 28 → 12, `p_shift` 20 → 8; they enter generated code a few thousand times
in the whole run. `p_index` is at 39 and `p_recursion` at 60.**

| | Interpreted | E121 | Now | In blocks | Instructions for each entry |
|---|---:|---:|---:|---:|---:|
| `p_shift` | 312 | 20 | 8 | 100% | 18455 |
| `p_ternary` | 299 | 28 | 12 | 100% | 49361 |
| `p_pointer` | 323 | 92 | 18 | 100% | 10957 |
| `p_if` | 304 | 192 | 23 | 100% | 38028 |
| `p_loop` | 329 | 107 | 28 | 100% | 5001 |
| `p_index` | 347 | 79 | 39 | 97% | 44 |
| `p_recursion` | 314 | 129 | 60 | 100% | 17 |
| `p_switch` | 298 | 193 | 114 | 86% | 6 |
| `p_funcptr` | 309 | 167 | 121 | 96% | 4 |
| `p_bignum` | 334 | 192 | 172 | 64% | 8 |
| `p_bytes` | 311 | 203 | 204 | 57% | 4 |

(Whole runs, the program's start included: for the fastest that start is now a large
part of the figure.)

- **What still leaves**: `p_recursion` comes back to the interpreter every 17
  instructions, at each RET; `p_switch` (6) and `p_funcptr` (4) at each jump through an
  operand. `p_index` has 3% of its instructions outside blocks, and they are a third of
  its cost. `p_bignum` and `p_bytes` are held by ADC, SBB and byte operations, which
  are not translated. The card's third branch, then, for these: a look-up of the
  target in generated code (the far way), and the kinds that are missing.
- **How a link is made.** A block begins with what an entry from another block needs:
  the time left is enough for the whole block, no flags' record is waiting if the
  block reads RFLAGS in memory (or builds on it: INC, DEC), and RIP is set; the
  interpreter enters behind that. An exit to a known address is a branch to the block
  there if there is one; if not, it is remembered by the address it waits for, and
  made into a branch when that block is translated. The time left is in a register,
  and every way out takes off what its block ran.
- **When blocks die.** A write to a page that holds a block drops every block: a link
  is a branch with nothing looked up, so nothing else is safe. A program that writes
  to its code's pages often will be slow by it.
- **`--jit-check` makes no links**: it checks one block at a time. Links are held by
  runs with `--jit`: what a program prints, its exit code, and the count of
  instructions, which the suites compare with a plain run's, now for a run cut short
  by `--max` too (blocks may run into one another only as far as the time left).
- **Too short to time.** With `--jit` these programs take 0.065 s, and that is the
  start of the emulator: the cycles of a whole run are within the noise of an empty
  one. `p_switch` and `p_funcptr`, which are not, come to about 250 million guest
  instructions a second, where QEMU had 511 and 292 (E117). The primitives need a
  count of rounds before the rest can be compared.
- **Wrong builds of the linking: 9 of 10 caught.** Eight at once: a record left waiting
  when a block that reads RFLAGS is entered (by a trace program run with `--jit`), the
  time not tested (by where a run cut short stops), RIP not set, an entry behind the
  checks, a count one too many. A write to a page of blocks that drops none passed:
  `j_mem`'s stores are made by the interpreter, after the block is left, and nothing
  then called the changed function through a link. It does now (a CALL inside a block,
  and the result compared before the exit code). Not held: an exit that waits for one
  address made into a branch to a block at another, which takes two addresses sharing
  an entry of the decode cache, one of them waited for.

**Next.** The far way: RET and the jumps through an operand looked up in generated
code. Then the kinds still missing (ADC and SBB, byte operations), and the primitives
given a count of rounds, so that they can be timed against QEMU.

## E123: the far way: RET and jumps through an operand, looked up in generated code (2026-11-20)

E122 left the programs that return and jump through operands coming back to the
interpreter each time: `p_recursion` every 17 instructions (60 host instructions for a
guest instruction), `p_switch` every 6 (114), `p_funcptr` every 4 (121).

- **Hypothesis**: **with the target of a RET, and of a CALL or JMP through an operand,
  looked up in the decode cache by generated code (the entry for the address, whether a
  block begins there, where its code is: about fourteen host instructions) and entered
  without leaving, those three primitives run a thousand instructions or more for each
  entry from the interpreter and come under 40.**
- **What changed since last time**: an exit whose target is not known when the block is
  translated no longer leaves generated code, in a program without a kernel.
- **Next move for each result**:
  - Under 40 → the kinds still missing (ADC and SBB, byte operations), then the
    primitives given a count of rounds and timed against QEMU
  - The look-up finds the block but the figure stays → the look-up's own cost is read
    in the listing (a cache of the last target at each exit is what QEMU and the 32-bit
    JIT do not have either)
  - The look-up misses → what the targets are (blocks under two instructions, a block
    that reads RFLAGS entered with a record waiting) is counted
- **Cut-off**: those three primitives; the suites; wrong builds of the look-up.

**Result: two of the three. `p_recursion` 60 → 37 host instructions for a guest
instruction, entered from the interpreter 44 times in all; `p_funcptr` 121 → 40;
`p_switch` 114 → 79, still left every 10 instructions.**

| | Interpreted | E122 | Now | In blocks | Instructions for each entry |
|---|---:|---:|---:|---:|---:|
| `p_recursion` | 313 | 60 | 37 | 100% | 276602 |
| `p_funcptr` | 309 | 121 | 40 | 99% | 67 |
| `p_switch` | 298 | 114 | 79 | 95% | 10 |
| `p_if` | 304 | 23 | 23 | 100% | 28231 |
| `p_loop` | 328 | 28 | 27 | 100% | 5000 |
| `p_pointer` | 323 | 18 | 18 | 100% | 21479 |
| `p_shift` | 312 | 8 | 8 | 100% | 36773 |
| `p_index` | 347 | 39 | 39 | 97% | 45 |
| `p_bignum` | 333 | 172 | 160 | 81% | 4 |
| `p_bytes` | 311 | 204 | 193 | 75% | 3 |

- **The look-up** is fifteen host instructions at one place in the mapping, reached by
  every exit whose target is in a register: the entry for the address as `dc_slot`
  finds it, its tag compared, whether a block begins there, where its code is; then
  into the block, which checks the time and the flags' record as for any link. A miss
  goes out. It reads the decode cache as it lies in memory, and is built only if a
  check at the start finds an entry 32 bytes long with the tag first.
- **One instruction is a block now**, where blocks are entered from one another: a case
  of a switch that is one JMP was not a block (two at least, E120), so every such case
  left generated code. `p_switch` went from 100 to 79 by that, `p_funcptr` from 47 to
  40.
- **What holds `p_switch` and `p_funcptr`** is the 1 to 5% of their instructions that
  are not translated: each sends the program out and in again. With `p_bignum` (ADC,
  SBB) and `p_bytes` (byte operations) that is the card's first branch: the missing
  kinds are next.
- **Wrong builds of the look-up: 3 of 7 caught**, and the other four change nothing a
  program can see (a look-up that misses is only slower; two conditions that cannot
  arise yet). The tag's comparison taken out passed at first: `j_slot` was rewritten
  for it, with a block translated again each round and a jump through a register to
  the address that shares its entry.

**Next.** ADC and SBB, the byte operations, and what `p_switch` still leaves for; then
the primitives with a count of rounds, timed against QEMU.

## E124: byte operations, ADC and SBB in blocks (2026-11-20)

What the interpreter still runs under `--jit`, counted by first byte in the primitives:
the group `80` and the ALU and TEST forms on bytes (`p_switch`, `p_funcptr`, `p_bytes`,
`p_index`: a `cmp byte` in front of a jump), ADC and SBB (`p_bignum`), rotations
(`p_sha`, `p_rotate`), MUL and DIV with one operand (`p_muldiv`), byte shifts
(`p_bitfield`). This entry takes the first two.

- **Hypothesis**: **with the ALU instructions on bytes translated so that the host's
  flags are the byte's (both operands shifted up 24 bits, as the 32-bit JIT does), and
  ADC and SBB taking the carry from the host's flags where the instruction before left
  it there, `p_switch` (79), `p_funcptr` (40), `p_index` (39), `p_bytes` (193) and
  `p_bignum` (160) run 99% of their instructions in blocks and come under 40.**
- **What changed since last time**: the flags' record takes a width of 8, and for ADC
  and SBB the carry that went in.
- **Next move for each result**:
  - Under 40 → rotations (their flags are dead nearly always: a look ahead in the
    block), MUL and DIV, byte shifts; then the timing against QEMU
  - In blocks but over 40 → the listing of the hot block is read
  - Still leaving → the counter again
- **Cut-off**: those five primitives; the suites; wrong builds.

**Result: two of the five under 40, two at it, one above. `p_bytes` 193 → 17 host
instructions for a guest instruction, `p_index` 39 → 22, `p_switch` 79 → 41, `p_funcptr`
40 → 40, `p_bignum` 160 → 56.**

| | Interpreted | E123 | Now | In blocks | Instructions for each entry |
|---|---:|---:|---:|---:|---:|
| `p_bytes` | 311 | 193 | 17 | 100% | 3997 |
| `p_index` | 347 | 39 | 22 | 99% | 746 |
| `p_switch` | 298 | 79 | 41 | 100% | 21 |
| `p_funcptr` | 310 | 40 | 40 | 99% | 67 |
| `p_bignum` | 333 | 160 | 56 | 95% | 18 |
| `p_muldiv` | 307 | 110 | 108 | 87% | 7 |
| `p_sha` | 323 | 112 | 111 | 85% | 9 |
| `p_rotate` | 301 | 71 | 71 | 81% | 142 |
| `p_bitfield` | 324 | 62 | 61 | 93% | 14 |

(The first five are the card's; the last four are what the next entry is for.)

- **Bytes**: the two operands are shifted up 24 bits and the operation done on 32, so
  the host's flags are the byte's and a `cmp byte` in front of a jump is one block with
  the jump, as for the wider operands. The record takes the width 8 and the
  interpreter's `alu` settles it as before.
- **ADC and SBB** take the carry from the host's flags when the instruction before in
  the block left it there (ADD, SUB, CMP, ADC, SBB; clear after the logic
  instructions), or from RFLAGS in memory when they are the first to set flags. The
  carry that went in is kept in the record, so that `alu` gives the flags it would have.
- **What still holds `p_bignum`, `p_switch` and `p_funcptr`**: 1 to 5% of their
  instructions are not translated, and each costs an entry. By the counter: MUL and DIV
  with one operand, rotations, byte shifts.
- **Wrong builds: 15 of 15 caught, after a test was written.** Seven at first, by the
  primitives. `j_bytes` (a trace test, expected from the real CPU) has what the other
  eight needed: a byte operation that is not the same both ways round with memory, a
  carry out of a byte that is none out of 32 bits read back from the record, the flags
  after OR on bytes with a comparison's flags stale before it, ADC after a logic
  instruction, ADC's own flags with the carry that went in, ADC first in its block,
  ADC after INC (not translated together: INC leaves the host's carry wrong), SBB after
  a borrow. One stretch of it did nothing at first, because a constant moved into one
  byte of a register was not translated and cut the block in front of what was to be
  tested: that MOV is translated now, with a wrong build and a stretch of its own.

**Next.** Rotations (their flags looked ahead for), MUL and DIV with one operand, byte
shifts. Then the primitives with a count of rounds, timed against QEMU.

## E125: rotations, MUL and DIV with one operand, byte shifts in blocks (2026-11-20)

The rest of what the counter of E124 showed the interpreter running under `--jit`.

- **Hypothesis**: **with ROL and ROR translated where the flags they set are overwritten
  before anything reads them (a look ahead in the block's page, which is nearly always
  so: an ADD or XOR follows), MUL, IMUL, DIV and IDIV with one operand (the divisions
  leaving the block before a fault or a quotient that needs more than 64 bits of
  dividend), and the byte shifts by a constant, `p_sha` (111), `p_rotate` (71),
  `p_muldiv` (108), `p_bitfield` (61) and `p_bignum` (56) run 99% of their instructions
  in blocks and come under 40.**
- **What changed since last time**: the first instruction translated without its
  flags, on the strength of what follows it; and ways out that test something other
  than an address.
- **Next move for each result**:
  - Under 40 → the same look ahead for every flag-setting instruction (the record is
    three host instructions each, most of them for nothing), and the primitives with a
    count of rounds, timed against QEMU
  - Still leaving → the counter again
- **Cut-off**: those five primitives; the suites; wrong builds.

**Result: two of the five under 40. `p_bignum` 56 → 16 host instructions for a guest
instruction and `p_muldiv` 108 → 16; `p_bitfield` 61 → 45, `p_sha` 111 → 47, `p_rotate`
71 → 71.**

| | Interpreted | E124 | Now | In blocks | Instructions for each entry |
|---|---:|---:|---:|---:|---:|
| `p_bignum` | 334 | 56 | 16 | 100% | 1719216 |
| `p_muldiv` | 307 | 108 | 17 | 100% | 2366561 |
| `p_bitfield` | 324 | 61 | 45 | 95% | 21 |
| `p_sha` | 322 | 111 | 47 | 98% | 22 |
| `p_rotate` | 301 | 71 | 71 | 81% | 142 |
| `p_pixel` | 323 | 43 | 18 | 100% | 2206335 |
| `p_index` | 347 | 22 | 21 | 100% | 14437 |
| `p_switch` | 298 | 41 | 39 | 100% | 24 |
| `p_funcptr` | 308 | 40 | 40 | 99% | 67 |

(The first five are the card's.)

- **MUL and DIV with one operand** were what held `p_bignum` and `p_muldiv`. A division
  leaves the block, before anything is changed, where the interpreter would fault (a
  divisor of zero, a quotient that does not fit) or where the dividend's upper half
  holds something a 64-bit division cannot take; otherwise it is one host division and
  one multiply-and-subtract.
- **Rotations: the look ahead is not enough for `p_rotate`.** Where an ADD or XOR
  follows (`p_sha`), a rotation is one host instruction and no record. In `p_rotate`
  the rotated value is returned or stored, and the next thing is a RET or a jump: the
  flags cannot be shown dead, and with a record waiting the rotation still ends the
  block. What that needs is a second record for an instruction that sets only some
  flags (so do INC and DEC, which are held to the first place in a block for the same
  reason). Not done here.
- **What the counter found beside the card's list**: a NOP with the prefix 66h, which
  is the compiler's padding in front of a loop, was refused with every other
  instruction of 16 bits, and each loop so padded left generated code once a round
  (`p_index` 14 thousand instructions an entry, from 746; `p_switch` 41 → 39); and
  MOVZX from AH, BH, CH or DH, which is how a pixel's second byte is taken (`p_pixel`
  43 → 18).
- **Still outside**: operations of 16 bits (`p_bitfield`'s other 5%), the rotations
  above, and whatever makes `p_switch` and `p_funcptr` leave every 24 and 67
  instructions with all their instructions in blocks: not an instruction that is not
  translated, so a block that will not be entered from another (it reads RFLAGS with a
  record waiting) or a look-up that misses. To be counted.
- **Wrong builds: 17 of 17 caught, after a test was written.** Eight at first. `j_arith`
  (a trace test, expected from the real CPU) has what the other nine needed: rotations
  by CL both ways, a rotation whose carry an ADC reads and one whose carry a jump reads
  (the look ahead must not call those dead), ROL of a register by a constant over one
  with OF set before it, MUL and IMUL of 32 bits with the upper half kept and with and
  without overflow read back from the record, a byte shifted right with its sign.
- **Where the blocks of `p_switch`, `p_funcptr` and `p_sha` leave**, counted by the
  address a block hands back with a record waiting:
  - `p_switch`: `cmp; je; jbe`, a second jump on the same comparison. A block ends at
    the first, the second begins a block that reads RFLAGS in memory, and with the
    comparison's record waiting it cannot be entered from the first. A million times.
  - `p_funcptr`: `or ah, 1`, an operation on one of the second bytes, not translated.
  - `p_sha`: `ror; ror; xor`: the look ahead stops at the second rotation, which it
    should pass (a rotation reads no flag).

**Next.** A block that goes on through a conditional jump's side that is not taken (so
that the second jump uses the host's flags); the look ahead passing instructions that
read no flag, and used for INC and DEC too; the second bytes. Then the primitives with
a count of rounds, timed against QEMU.

## E126: against QEMU, with programs long enough to time (a measurement; 2026-11-20)

The primitives run a tenth of a second or less, and with `--jit` the fast ones are lost
in the emulator's start (E122). A first try at timing them as they are, forty runs each
less the time of a program that does nothing, gave times of a few thousandths of a
second and some below zero, for QEMU as for g86m: not kept. `tools/prim64_long.sh`
builds each primitive again on the real machine with its `main` called thirty times,
and times it under QEMU's user mode (11.0.3, in a container for arm64), under Docker's
own emulator (Rosetta) and under g86m with `--jit`, each less a program that does
nothing. Same host as E117, an Apple M1; its load was between 1.6 and 4.6.

- **Hypothesis**: **after E120 to E125 the integer primitives that run in blocks are
  within a factor of three of QEMU; the ones known to leave generated code (16-bit
  operations, rotations whose flags cannot be shown dead) and the floating point are
  ten times or more behind.**
- **What changed since last time**: E117 measured the interpreter (24 to 47 million
  guest instructions a second, QEMU 6 to 200 times faster), with programs too short for
  what there is now.
- **Next move for each result**:
  - Within three → the plan stands: the blocks through a jump not taken, the second
    record, 16 bits; then the floating point, where the distance is
  - An integer primitive in blocks more than three behind → its hot block's listing
    against what QEMU makes of the same loop
  - Ahead of QEMU somewhere → said so, with the same care about how rough it is
- **Cut-off**: one run of the script.

**Result: g86m is ahead of QEMU on five primitives, within a factor of three on nine
more, and far behind where it was expected to be.** Million guest instructions a second:

| | Guest instructions (millions) | QEMU | Docker's own (Rosetta) | g86m `--jit` | g86m / QEMU |
|---|---:|---:|---:|---:|---:|
| `p_muldiv` | 923 | 1405 | 9515 | 5698 | 4.06 |
| `p_recursion` | 365 | 1567 | 3319 | 2745 | 1.75 |
| `p_funcptr` | 629 | 455 | 1486 | 699 | 1.54 |
| `p_loop` | 451 | 3988 | 15023 | 5778 | 1.45 |
| `p_fill` | 234 | 536 | 3211 | 593 | 1.11 |
| `p_pointer` | 989 | 3495 | 9245 | 3319 | 0.95 |
| `p_bignum` | 1341 | 3412 | 10083 | 3097 | 0.91 |
| `p_if` | 690 | 2439 | 4827 | 2001 | 0.82 |
| `p_index` | 898 | 3494 | 14254 | 2833 | 0.81 |
| `p_ternary` | 1182 | 10743 | 16881 | 8206 | 0.76 |
| `p_bytes` | 1038 | 5112 | 11531 | 3858 | 0.75 |
| `p_switch` | 773 | 834 | 1840 | 584 | 0.70 |
| `p_pixel` | 794 | 10316 | 13935 | 6157 | 0.60 |
| `p_shift` | 2213 | 16598 | 21417 | 7041 | 0.42 |
| `p_ldbl` | 416 | 115 | 47 | 35 | 0.31 |
| `p_dbl_conv` | 1015 | 298 | 7251 | 53 | 0.18 |
| `p_sha` | 505 | 7534 | 13643 | 840 | 0.11 |
| `p_dbl_arith` | 647 | 505 | 2134 | 52 | 0.10 |
| `p_float` | 693 | 589 | 2501 | 52 | 0.09 |
| `p_dbl_cmp` | 1124 | 885 | 9365 | 59 | 0.07 |
| `p_rotate` | 2673 | 4091 | 5939 | 270 | 0.07 |
| `p_bitfield` | 2029 | 11936 | 14847 | 524 | 0.04 |
| `p_simd` | 498 | 1477 | 8735 | 36 | 0.02 |

- **Ahead** (1.1 to 4 times): `p_muldiv`, `p_recursion`, `p_funcptr`, `p_loop`,
  `p_fill`. These are where E117 found QEMU slowest: division, RET, jumps through an
  operand. g86m's look-up for a RET's target and its division with a way out are
  cheaper than what QEMU does there.
- **Within three** (0.4 to 0.95): `p_pointer`, `p_bignum`, `p_if`, `p_index`,
  `p_ternary`, `p_bytes`, `p_switch`, `p_pixel`, `p_shift`. QEMU is at 2,400 to 16,600
  on these and g86m at 600 to 8,200. What g86m pays that QEMU does not is known: the
  flags' record made at every flag-setting instruction, constants built in up to four
  instructions, and a block ended at every conditional jump.
- **Far behind**: the floating point (0.02 to 0.3: nothing of SSE or the x87 is
  translated), `p_sha` and `p_rotate` (rotations), `p_bitfield` (16-bit operations).
  All three were named before the measurement (E125).
- **Rosetta** is 1.3 to 25 times faster than QEMU and is not the yardstick; g86m passes
  it nowhere but on `p_ldbl`'s neighbourhood, where both are slow.
- **How rough**: three runs of each, the fastest for g86m and the mean for the two in
  the container, whose clock reads hundredths of a second: a run of 0.13 s is known to
  a tenth. g86m's start (0.067 s) is taken off. The first run of this script stopped
  g86m at its default limit of two billion instructions on three programs; they were
  timed again without it, and the script now lifts the limit.

**Next.** As planned (E125's next), then the scalar SSE instructions.

## E127: a block goes on through a conditional jump that is not taken (2026-11-21)

E125 counted where blocks hand back to the interpreter with a record waiting: a second
jump on one comparison (`cmp; je; jbe`, a million times in `p_switch`), two rotations in
a row (`p_sha`), an operation on AH (`p_funcptr`). E126 put those three primitives at
0.70, 0.11 and 1.54 of QEMU.

- **Hypothesis**: **with a conditional jump no longer ending its block (the taken side
  leaves by a branch to a way out behind the block, the other side is translated on, so
  a second jump uses the host's flags), the look ahead for dead flags passing every
  instruction that reads none (rotations, INC, DEC) and used for INC and DEC as for
  rotations, and the group `80` on AH, BH, CH and DH, `p_switch` and `p_sha` run a
  thousand instructions or more for each entry and `p_switch` (39 host instructions for
  a guest instruction), `p_sha` (47) and `p_funcptr` (40) come under 30; nothing else
  gets worse.**
- **What changed since last time**: a block is no longer a run between two jumps. It
  has ways out in its middle that are links.
- **Next move for each result**:
  - Under 30 → the record made only where something can read it (the same look ahead,
    for every flag-setting instruction), then against QEMU again
  - A primitive gets worse → blocks have grown past what is run of them: the count of
    instructions in a block against those run for each entry
  - Still leaving → the counter of E125 again
- **Cut-off**: the primitives' table; the suites; wrong builds.

**Result: `p_switch` 39 → 21 host instructions for a guest instruction and `p_funcptr`
40 → 29, both under 30 and entered from the interpreter a few hundred times in all;
`p_sha` 47 → 31, just over. Nothing got worse.**

| | Interpreted | E125 | Now | In blocks | Instructions for each entry |
|---|---:|---:|---:|---:|---:|
| `p_switch` | 298 | 39 | 21 | 100% | 162120 |
| `p_funcptr` | 309 | 40 | 29 | 100% | 215895 |
| `p_sha` | 323 | 47 | 31 | 98% | 268 |
| `p_if` | 304 | 23 | 22 | 100% | 676739 |
| `p_index` | 347 | 21 | 21 | 100% | 14416 |
| `p_pointer` | 323 | 18 | 18 | 100% | 824310 |
| `p_loop` | 329 | 28 | 28 | 100% | 1251997 |
| `p_recursion` | 314 | 38 | 37 | 100% | 276602 |
| `p_bitfield` | 324 | 45 | 46 | 95% | 21 |
| `p_rotate` | 301 | 71 | 71 | 81% | 142 |

- **A conditional jump no longer ends its block.** Taken, it leaves by a branch to a way
  out behind the block, which is a link like any other exit; not taken, the block goes
  on, and a second jump on the same comparison uses the host's flags.
- **The look ahead for dead flags** passes the instructions that read no flag (ROL and
  ROR, INC and DEC, a shift by CL), and INC and DEC are translated without a record
  where their flags are dead, as the rotations are.
- **`p_sha`** still hands back every 268 instructions, and 2% of its instructions are
  not in blocks: to be counted. `p_rotate` and `p_bitfield` are as they were (the
  second record, 16 bits).
- **Wrong builds: 11 of 11 caught, with `j_arith` extended.** Nine by the first
  extension (INC and DEC with their flags dead, an INC whose ZF is read past a shift by
  zero, a rotation's carry read by RCL, the group `80` on AH, two jumps on one
  comparison). The two that passed were in the look ahead: RCL by a constant taken for
  an instruction that reads no flag, and a jump through a register passed as if what
  lies behind it were run next. The second needed the instruction behind the jump to
  have been run once, since the look ahead reads only what the decode cache knows; the
  test goes through it the first time round.
- **The real CPU was out of reach for part of this entry** (the VPN to its host was
  down): the test was first run here only, three ways, and its trace taken when the
  host was back.

## E128: the flags' record made only where something can read it (2026-11-21)

Every flag-setting instruction in a block leaves a record: its two operands and what it
was, three host instructions (more with a constant). E126 named it first among what g86m
pays and QEMU does not on the integer primitives that are within a factor of three.
E125's look ahead already says, for a rotation, INC or DEC, whether the flags are
overwritten before anything reads them.

- **Hypothesis**: **with the same look ahead asked for every instruction that sets all
  six flags, and no record made where it says they are dead, the integer primitives
  lose two to four host instructions for each guest instruction (`p_loop` 28, `p_if`
  22, `p_pointer` 18, `p_index` 21, `p_bytes` 17), and nothing changes in what a
  program computes.**
- **What changed since last time**: nothing in what is translated; less is generated.
- **Next move for each result**:
  - Two or more off → against QEMU again (`tools/prim64_long.sh`), then the scalar SSE
  - Under one off → the records were not where the cost is: a hot block's listing is
    read, host instruction by host instruction
  - `--jit-check` finds a difference → a case where dead flags are read after all: that
    case, with a test
- **Cut-off**: the primitives' table; the suites; wrong builds.

**Result: one to two host instructions off each guest instruction, under the card's two
to four. `p_index` 21 → 18.6, `p_shift` 8 → 6.5, `p_pixel` 17 → 15.7, `p_loop` 28 →
26.4, `p_if` 22 → 21.2, `p_pointer` 18 → 16.9.**

| | E127 | Now |
|---|---:|---:|
| `p_shift` | 8 | 6.5 |
| `p_ternary` | 12 | 11.5 |
| `p_bignum` | 16 | 14.4 |
| `p_muldiv` | 16 | 15.1 |
| `p_pixel` | 17 | 15.7 |
| `p_bytes` | 17 | 15.8 |
| `p_pointer` | 18 | 16.9 |
| `p_index` | 21 | 18.6 |
| `p_switch` | 21 | 20.2 |
| `p_if` | 22 | 21.2 |
| `p_loop` | 28 | 26.4 |
| `p_funcptr` | 29 | 28.9 |
| `p_sha` | 31 | 30.0 |
| `p_recursion` | 37 | 36.1 |

(Whole runs, the program's start included, which is now a third of the fastest ones'
figure; the next comparison with QEMU uses the long programs.)

- **`--jit-check` found a difference at once, and it was the check that had to
  change.** A block whose last flag-setting instruction made no record leaves with the
  flags of an earlier one; the same instructions interpreted leave with the right
  ones; RFLAGS differ, and nothing can read them. The check compared them all the
  same. (The rotations of E125 and the INC and DEC of E127 could have tripped it in the
  same way, and did not only because the instruction that overwrites their flags was in
  the same block in every test.) A block now says at each way out whether its flags are
  stale, and the check leaves RFLAGS uncompared there; the registers, RIP and memory
  are compared as before, and the run goes on with the interpreter's state.
- **Where the rest of the cost is** is the card's second branch, by half: the record
  was one to two of the 16 to 26, not the first thing. A hot block's listing is to be
  read before more is guessed.
- **Wrong builds: 7 of 8 caught, with `j_arith` extended twice more.** Two passed at
  first. ADC taken for an instruction that sets all flags and reads none: the test's
  ADC behind a rotation took its carry from RFLAGS as the loop's last round left it,
  which happened to be the carry the rotation makes; the round now ends with no carry.
  NOT taken for an instruction that sets all flags: a comparison in front of it made no
  record, and the jump behind it used the host's flags and was right; the jump is in
  the next block now, where it reads the record. The one not caught makes the check
  compare RFLAGS nowhere: a check that looks at less cannot be caught by programs that
  are right.

**Next.** A hot block's listing read, for where the 16 to 26 host instructions go; the
comparison with QEMU on the long programs; then the scalar SSE.

## E129: a hot block's listing read, and what it wastes taken out (2026-11-21)

E128 guessed where the cost was and was half wrong. This entry reads the host code first.
Two things had to be made for it: the blocks written out as they are installed and
disassembled, and a measure that is not swamped by the emulator's start (which is now a
third to two thirds of a primitive's whole run): the long programs of E126, less a
program that does nothing. By that measure, host instructions for a guest instruction:
`p_shift` 1.7, `p_pixel` 2.6, `p_ternary` 2.7, `p_loop` 3.5, `p_muldiv` 3.7, `p_bytes`
5.6, `p_if` 6.0, `p_pointer` 6.4, `p_bignum` 6.5, `p_switch` 6.6, `p_index` 7.0,
`p_recursion` 7.6, `p_sha` 9.3, `p_funcptr` 12.3. (The table figures of E120 to E128,
8 to 40, were whole runs.)

`p_loop`'s inner loop is five guest instructions (MOV, XOR, ADD, SUB of 1, JNE) and
eighteen host instructions a round:

    mov x9, x14 / eor x9, x9, x8 / tst x9, x9 / adds x10, x10, x9      MOV, XOR, ADD
    mov x1, #1 / mov x5, x8 / mov x6, x1 / mov x7, #0x4006 / subs x8, x8, x1    SUB
    b.ne / add x1, x25, #0 / sub x0, x0, #5 / b                         JNE, taken: the link
    cmp x0, #5 / b.lo / nop / mov x25, x1 / b                           the block's own entry

- **Hypothesis**: **eight of the eighteen are the link from the block to itself, and
  three more are plain waste: with a block's branch back to itself made a count, a
  test and a branch (three instructions for eight), no TST behind an OR or XOR whose
  flags are dead, constants under 4096 taken by ADD, SUB and CMP as they are, and
  displacements under 4096 added in one instruction where a load or store or LEA built
  them in up to five, `p_loop` goes from 3.5 host instructions for a guest instruction
  to under 2.5, and the primitives that work on memory (`p_pointer` 6.4, `p_index` 7.0,
  `p_bytes` 5.6) lose one or more.**
- **What changed since last time**: the measure, and that the listing was read before
  the guess.
- **Next move for each result**:
  - As guessed → the three host instructions of the record at a flag-setting
    instruction in front of a conditional jump, where the flags are dead on both sides
    of the jump (the SUB above); then the checks at a load and a store (four and
    eleven host instructions)
  - Less → the listing again, of the block that did not move
- **Cut-off**: the measure above on the same programs; the suites; wrong builds.

**Result: as guessed. `p_loop` 3.5 → 2.1 host instructions for a guest instruction;
`p_bytes` 5.6 → 4.2, `p_index` 7.0 → 5.5, `p_pointer` 6.4 → 5.2; every primitive
measured went down.**

| | E128 | Now | Cycles for a guest instruction now |
|---|---:|---:|---:|
| `p_shift` | 1.73 | 1.43 | 0.16 |
| `p_loop` | 3.49 | 2.12 | 0.28 |
| `p_pixel` | 2.56 | 2.18 | 0.27 |
| `p_ternary` | 2.67 | 2.34 | 0.25 |
| `p_muldiv` | 3.74 | 3.39 | 0.45 |
| `p_bytes` | 5.59 | 4.17 | 0.49 |
| `p_pointer` | 6.43 | 5.15 | 0.69 |
| `p_index` | 6.99 | 5.48 | 0.71 |
| `p_if` | 5.99 | 5.70 | 1.17 |
| `p_bignum` | 6.52 | 5.76 | 0.69 |
| `p_switch` | 6.57 | 6.27 | 2.11 |
| `p_recursion` | 7.64 | 6.80 | 0.72 |
| `p_sha` | 9.34 | 8.99 | 1.24 |
| `p_funcptr` | 12.25 | 12.05 | 2.81 |

(The long programs of E126 less a program that does nothing: `tools/prim64_net.py`.
`p_shift` runs a guest instruction in a sixth of a cycle; the real machine takes about a
quarter to a third.)

- **The branch back to the block itself** is a count, a test and a branch where it was
  eight instructions; filled in when the block's length is known, and not at all if
  the block reads RFLAGS in memory (it then goes round by its entry, which looks
  whether a record is waiting).
- **Constants under 4096** go into ADD, SUB and CMP as they are; **displacements**
  under 4096 either way are one ADD or SUB at a load, a store or LEA.
- **No TST behind an OR or XOR whose flags are dead.**
- **What is next in the listing**: the record at a flag-setting instruction right in
  front of a conditional jump (three host instructions, and the flags are usually dead
  on both sides of the jump); a link to another block (seven); the checks at a load
  (four) and at a store (eleven). And `p_funcptr` at 12 and `p_switch` at 6 with two
  to three cycles an instruction: the look-up of a jump's target, where the host
  cannot guess the branch.
- **Wrong builds: 13 of 13 caught.** The one that needed a test was the branch back
  taken straight to the body of a block that reads RFLAGS in memory: `j_bytes` has a
  loop that begins with ADC and ends with a SUB and a jump back, and compares the sum.

**Next.** The record in front of a conditional jump, where the flags are dead on both
sides; then the link to another block and the checks at a load and a store; then the
time against QEMU again, on a quiet host.

## E130: no record in front of a conditional jump whose two sides overwrite the flags (2026-11-21)

E129's listing: the SUB in front of `p_loop`'s JNE makes a record (three host
instructions) although the jump uses the host's flags and the flags are set again on
both sides of it before anything reads them. The look ahead of E125 stops at any jump.

- **Hypothesis**: **where the instruction right behind a flag-setting instruction is a
  conditional jump that will use the host's flags, and the flags are dead at the jump's
  target and behind the jump, no record is needed; that is the usual shape of a loop's
  end and of an `if`, so `p_loop` (2.1 host instructions for a guest instruction),
  `p_if` (5.7), `p_switch` (6.3) and `p_index` (5.5) lose half an instruction or more
  each.**
- **What changed since last time**: a jump on a condition takes the host's flags
  wherever they are good, also when no record was made in the block (it looked for the
  record first).
- **Next move for each result**:
  - Half or more off → the link to another block (seven host instructions), then the
    checks at a load and a store
  - Less → how often the flags are dead at both sides is counted at translation
  - `--jit` differs from a plain run → the promise that the jump is translated in the
    same block was broken somewhere: that place, with a test
- **Cut-off**: `tools/prim64_net.py` on the long programs; the suites; wrong builds.

**Result: the hypothesis as written was wrong, and what it was after was got another
way. `p_loop` 2.1 → 1.5 host instructions for a guest instruction, `p_if` 5.7 → 4.6,
`p_pointer` 5.2 → 4.6, `p_switch` 6.3 → 5.8, `p_index` 5.5 → 5.2.**

| | E129 | Now |
|---|---:|---:|
| `p_shift` | 1.43 | 1.34 |
| `p_loop` | 2.12 | 1.50 |
| `p_pixel` | 2.18 | 2.09 |
| `p_ternary` | 2.34 | 2.22 |
| `p_muldiv` | 3.39 | 3.29 |
| `p_bytes` | 4.17 | 4.16 |
| `p_pointer` | 5.15 | 4.57 |
| `p_if` | 5.70 | 4.61 |
| `p_index` | 5.48 | 5.18 |
| `p_bignum` | 5.76 | 5.49 |
| `p_switch` | 6.27 | 5.76 |
| `p_recursion` | 6.80 | 6.46 |
| `p_sha` | 8.99 | 8.84 |
| `p_funcptr` | 12.05 | 11.68 |

- **The look ahead on both sides of the jump moved nothing** (`p_loop` 2.12 → 2.11).
  The listing said why: the look ahead reads the decode cache, which knows only what has
  been run, and when a loop is translated (at its eighth round) the instruction behind
  its closing jump has never been run. The flags could not be shown dead on that side,
  so the record stayed, on the side that is run a thousand times because of the side
  that is run once.
- **So the record is put off, not left out.** Where a conditional jump comes right
  behind an ADD, SUB, CMP, TEST, AND, OR or XOR, the instruction makes no record; the
  jump uses the host's flags; and the record is made on each side of the jump where
  the flags are not known to be dead: on the side taken, in the way out behind the
  block; on the other, right behind the jump. The operands are still there to make it
  from: CMP and TEST change nothing, the first operand of a SUB or ADD is the result
  with the second put back, and a logic instruction's flags are its result's. In
  `p_loop` the record is now three instructions on the way out of the loop.
- **A hole found while writing the test, before any test ran**: a jump whose condition
  the host's flags cannot give (parity) took the flags from RFLAGS in memory when no
  record had been made in the block, and with the record put off none had. The jump
  now ends the block in that case, and the record is made in front of it. `j_sink` has
  the case.
- **Wrong builds: 10 of 11 caught; the one left changes nothing.** Three passed at first.
  The hole of the paragraph above, put back: the test's jump on parity found the same
  parity in RFLAGS as the comparison made, and now does not. The regimes of ADD and SUB
  swapped in the look past the jump: it then promises that `add; ja` will be one block,
  which it cannot be, and makes no record where the flags are dead on both sides; a
  stretch for that. And the register a put-off record is made from taken to be the
  first operand's and not the result's: they are the same register wherever it matters.

**Next.** The link to another block (seven host instructions), the checks at a load and
a store (four and eleven); the time against QEMU on a quiet host.

## E131: against QEMU again, after E127 to E130 (a measurement; 2026-11-21)

`tools/prim64_long.sh` as in E126: each primitive's work done thirty times, under QEMU's
user mode (11.0.3), Docker's own emulator (Rosetta) and g86m with `--jit`, less a
program that does nothing. Same host; its load was about 3.

- **Hypothesis**: **the integer primitives that were at 0.4 to 0.95 of QEMU in E126 are
  at QEMU's speed or past it now (the block through a jump not taken, the record put
  off or left out, the branch back to a block's own start); the floating point, the
  rotations whose flags are needed and the 16-bit operations are where they were.**
- **What changed since last time**: E127 to E130.
- **Next move for each result**:
  - At or past QEMU on the integer primitives → the scalar SSE instructions, where the
    distance now is; the kernel's memory (task 5) behind that
  - An integer primitive still under 0.8 → its hot block's listing
- **Cut-off**: one run of the script.

**Result: g86m is at or past QEMU on thirteen of the fourteen integer primitives that
run in blocks, and the rest are where they were.** Million guest instructions a second:

| | QEMU | Docker's own (Rosetta) | g86m `--jit` | g86m / QEMU | In E126 |
|---|---:|---:|---:|---:|---:|
| `p_muldiv` | 1398 | 9515 | 6195 | 4.43 | 4.06 |
| `p_recursion` | 1541 | 3319 | 3726 | 2.42 | 1.75 |
| `p_funcptr` | 461 | 1486 | 1056 | 2.29 | 1.54 |
| `p_loop` | 3756 | 16693 | 7907 | 2.11 | 1.45 |
| `p_switch` | 834 | 1853 | 1426 | 1.71 | 0.70 |
| `p_bignum` | 3378 | 10315 | 4515 | 1.34 | 0.91 |
| `p_pointer` | 3411 | 9245 | 4192 | 1.23 | 0.95 |
| `p_index` | 3454 | 14967 | 3991 | 1.16 | 0.81 |
| `p_shift` | 16154 | 22131 | 18290 | 1.13 | 0.42 |
| `p_bytes` | 5014 | 12504 | 5520 | 1.10 | 0.75 |
| `p_fill` | 541 | 3211 | 587 | 1.09 | 1.11 |
| `p_if` | 2439 | 4827 | 2547 | 1.04 | 0.82 |
| `p_ternary` | 10458 | 16881 | 10743 | 1.03 | 0.76 |
| `p_pixel` | 9929 | 13935 | 9236 | 0.93 | 0.60 |
| `p_ldbl` | 114 | 48 | 36 | 0.31 | 0.31 |
| `p_sha` | 7534 | 13643 | 2305 | 0.31 | 0.11 |
| `p_dbl_conv` | 301 | 9855 | 53 | 0.18 | 0.18 |
| `p_dbl_arith` | 554 | 2155 | 53 | 0.10 | 0.10 |
| `p_float` | 569 | 2566 | 52 | 0.09 | 0.09 |
| `p_rotate` | 4068 | 5979 | 281 | 0.07 | 0.07 |
| `p_dbl_cmp` | 894 | 9605 | 60 | 0.07 | 0.07 |
| `p_bitfield` | 12448 | 15256 | 612 | 0.05 | 0.04 |
| `p_simd` | 1495 | 9958 | 37 | 0.02 | 0.02 |

- **Past QEMU by more than half**: `p_muldiv` (4.4 times), `p_recursion` (2.4),
  `p_funcptr` (2.3), `p_loop` (2.1), `p_switch` (1.7). `p_switch` was at 0.70: the
  second jump on one comparison.
- **At QEMU's speed to a third past it**: `p_bignum`, `p_pointer`, `p_index`,
  `p_shift`, `p_bytes`, `p_fill`, `p_if`, `p_ternary`. `p_shift` was at 0.42 and is
  at 18 billion guest instructions a second, which is Rosetta's neighbourhood.
- **Just under**: `p_pixel` 0.93.
- **Where it was**: the floating point (0.02 to 0.31: nothing of SSE or the x87 is
  translated), `p_rotate` 0.07, `p_bitfield` 0.05. `p_sha` went from 0.11 to 0.31 by
  the look ahead through rotations.
- **How rough**: as E126 (three runs, a clock of hundredths of a second in the
  container); the load was not low. A ratio of 1.03 or 0.93 is "the same".
- **What this is not**: these are programs without a kernel, small, with their loops
  hot. A kernel booted is still run with register-only blocks (the boot 276 → about
  200 host instructions for a guest instruction, E120), and QEMU's user mode is not
  QEMU's machine either.

**Next.** The scalar SSE instructions (task 8). Behind them the kernel's memory through
the TLB (task 5), rotations with a second record, 16 bits.

**Why g86m is ahead where it is (read off QEMU's own host code).** `qemu-x86_64 -d
in_asm,out_asm` writes each translated block; this build has no disassembler and gives
the bytes, which were disassembled here. For the same guest code:

| | QEMU 11.0.3 | g86m |
|---|---|---|
| `p_loop`'s inner loop, five guest instructions, a round | 21 host instructions: 4 loads and 8 stores | 8 host instructions: no load, no store |
| The guest's registers | in memory (`env`): loaded where read, stored where written | in host registers for the whole block |
| The flags | the last result, operand and operation stored to memory at each flag-setting instruction (3 stores) | the host's flags; a record only on a way out where they may be read |
| The start of every block | a load and a test (has the block been asked to stop), and a store | a count and a test where one block enters another; nothing on the way back to a block's own start beyond them |
| RET, CALL and JMP through an operand | a call to a C function that looks the target up, then a jump | fifteen instructions of look-up in generated code |
| DIV and IDIV | a call to a C function for each | one host division and a multiply-and-subtract, with ways out |

QEMU's loop for `mov rcx, rsi; xor rcx, rax; add rdx, rcx; sub rax, 1; jne`:

    ldur w20, [x19, #-16] / tbnz w20, #31 / sturb wzr, [x19, #-12]
    ldr x20, [x19, #48] / ldr x21, [x19] / eor x20, x20, x21 / str x20, [x19, #8]
    ldr x22, [x19, #16] / add x20, x22, x20 / str x20, [x19, #16]
    sub x20, x21, #1 / str x20, [x19] / str x20, [x19, #272]
    mov w21, #1 / str x21, [x19, #280] / mov w21, #1 / sturb w21, [x19, #-12]
    mov w21, #19 / str w21, [x19, #296] / cbnz x20 / b

g86m's:

    mov x9, x14 / eor x9, x9, x8 / adds x10, x10, x9 / subs x8, x8, #1 / b.ne
    sub x0, x0, #5 / cmp x0, #5 / b.hs

This is not QEMU done badly. Its translator is one for every guest and host it has,
goes through an intermediate code, serves a whole machine as well as a program, and
keeps the guest's state where any helper can find it. g86m's does one guest on one
host, and for now only a program without a kernel.

## E132: the scalar SSE instructions in blocks (the JIT's eighth task; 2026-11-21)

E131: the floating point is where the distance to QEMU is, 0.02 to 0.31 of its speed,
because nothing of SSE is translated: an SSE instruction ends its block and is
interpreted at 280 host instructions. QEMU does its floating point in software, a call
for each operation, and is itself slow there (300 to 900 million guest instructions a
second, where it does 3,000 to 16,000 on integers).

The interpreter does scalar arithmetic with the host's own (Goose's f64), and puts right
by hand only what the host does otherwise: which operand that is not a number comes out,
and the sign of the one made from nothing. So generated code can use the host's
instructions for everything else, and leave the block, before it changes anything, where
a result is not a finite number.

- **Hypothesis**: **with the XMM registers left in memory and each instruction a load,
  the host's operation and a store (MOVSS and MOVSD, MOVAPS, MOVUPS, MOVDQA, MOVDQU, MOVD
  and MOVQ; ADD, SUB, MUL, DIV and SQRT on scalars; the conversions between integers,
  singles and doubles; UCOMIS and COMIS with the jump behind them on the host's flags;
  the 128-bit AND, OR, XOR and ANDN), `p_dbl_arith`, `p_float`, `p_dbl_conv` and
  `p_dbl_cmp` run nine tenths of their instructions in blocks and go from about 50
  million guest instructions a second to over 500, which is QEMU's speed on them.**
- **What changed since last time**: a block may begin at an instruction the short front
  has no kind for; `--jit-check` compares the XMM registers too.
- **Next move for each result**:
  - At QEMU's speed or past → the XMM registers kept in host registers through a block
    (they are loaded and stored at every use now), if the listing says that is the cost
  - In blocks but slow → the listing
  - Not in blocks → the counter: which instruction still ends them (MIN and MAX, the
    packed forms, CVTSD2SI with rounding)
  - `--jit-check` differs → a case where the host's arithmetic is not the chip's and no
    way out was made: that case, with a test from the real CPU
- **Cut-off**: `tools/prim64_net.py` and `tools/prim64_long.sh` on those four; the
  suites; wrong builds.

**Result: all four run in blocks and cost a fiftieth of what they did. Host instructions
for a guest instruction, net of start-up: `p_dbl_arith` about 400 → 8.9, `p_float` about
400 → 8.5, `p_dbl_conv` 6.3, `p_dbl_cmp` 5.3. The time against QEMU is to be taken when
the wrong builds are done.**

| | Host instructions for a guest instruction | Cycles for a guest instruction |
|---|---:|---:|
| `p_dbl_cmp` | 5.3 | 1.0 |
| `p_dbl_conv` | 6.3 | 1.2 |
| `p_float` | 8.5 | 3.2 |
| `p_dbl_arith` | 8.9 | 3.5 |

- **What is translated**: MOVSS and MOVSD (all forms), MOVAPS, MOVAPD, MOVUPS, MOVUPD,
  MOVDQA, MOVDQU, MOVD and MOVQ in both directions; ADD, SUB, MUL, DIV and SQRT on
  scalars; MIN and MAX on scalars; CVTSI2SS and CVTSI2SD, CVTTSS2SI and CVTTSD2SI,
  CVTSS2SD and CVTSD2SS; UCOMIS and COMIS; ANDPS, ANDNPS, ORPS, XORPS and their PD
  forms, PAND, POR, PXOR. Only in a program without a kernel.
- **Where the host is not the chip.** The arithmetic leaves the block, with nothing
  changed, if its result is not a finite number (the chip's choice of which NaN comes
  out is the interpreter's to make); that test is four host instructions and leaves the
  host's flags alone. A conversion to an integer that is out of range or of a NaN gives
  the chip's "integer indefinite" by two conditional selects, with no way out: the
  first version left the block there, and `p_dbl_conv`, which converts such values a
  million times, was at 58 host instructions for a guest instruction. MIN and MAX are
  one comparison and one select, which gives the second operand for a NaN and for equal
  zeros as the chip does.
- **UCOMIS and COMIS** set the host's flags by FCMP, and a jump behind them on "above",
  "below" or parity uses those; "equal" after a comparison of floats is "equal or
  unordered", which no single host condition says, and ends the block. Their record is
  the two values, settled by the interpreter's own code (now a function both use).
- **A block may begin at an SSE instruction**, which the short front has no kind for;
  the place that enters a block falls through to the rest of the CPU for it.
- **`--jit-check` compares the XMM registers** too.
- **The cycles say what is next**: 3.5 cycles for a guest instruction in `p_dbl_arith`
  at 9 host instructions, where the integer primitives take 0.2 to 0.7 at 2 to 5. An
  XMM register is stored to memory by one instruction and loaded by the next, and a
  sum carried round a loop goes through memory every time. Keeping the XMM registers
  in host registers through a block is the card's first branch.

- **Wrong builds: 28 of 28 caught, after `x_blocks` was extended three times.** Twenty-one
  at first. The seven that passed, and what each wanted of the test:
  - A value has to live to the end of its block, or be tested: MIN of a NaN was right in
    the interpreter and wrong in the block, and the register was loaded again further
    down the same block, so the check, which compares at a block's end, saw nothing. A
    comparison and a jump right behind the MIN now hold it, for `--jit` alone as well.
  - What comes behind a way out in the same block is interpreted. The results that are
    not finite were one stretch, so only the first was ever run as a block; each is a
    block's last now.
  - A stretch reached only by a jump from a block is translated late (its arrivals are
    counted only when a block hands back to the interpreter), and fourteen rounds were
    not enough for the later stretches under `--jit`: forty.
  - Registers and memory whose other half is not zero, for MOVD both ways and MOVQ's
    other opcode; and a read of what a sixteen-byte store then overwrites, for the
    check's own log.
- **Against QEMU** (`tools/prim64_long.sh`, the host's load about 4; million guest
  instructions a second):

  | | QEMU | Rosetta | g86m `--jit` | g86m / QEMU |
  |---|---:|---:|---:|---:|
  | `p_dbl_conv` | 283 | 9228 | 2707 | 9.58 |
  | `p_muldiv` | 1413 | 9230 | 6640 | 4.70 |
  | `p_dbl_cmp` | 818 | 9137 | 3139 | 3.84 |
  | `p_recursion` | 1460 | 3231 | 3884 | 2.66 |
  | `p_loop` | 3852 | 13658 | 9589 | 2.49 |
  | `p_funcptr` | 439 | 1406 | 1071 | 2.44 |
  | `p_dbl_arith` | 449 | 2040 | 886 | 1.97 |
  | `p_switch` | 831 | 1810 | 1426 | 1.72 |
  | `p_float` | 587 | 2448 | 985 | 1.68 |
  | `p_bignum` | 2698 | 8940 | 4515 | 1.67 |
  | `p_bytes` | 4324 | 11159 | 5702 | 1.32 |
  | `p_pointer` | 3447 | 8993 | 4416 | 1.28 |
  | `p_shift` | 16640 | 21486 | 20683 | 1.24 |
  | `p_fill` | 513 | 3044 | 590 | 1.15 |
  | `p_index` | 3454 | 13403 | 3973 | 1.15 |
  | `p_ternary` | 10458 | 16881 | 11473 | 1.10 |
  | `p_if` | 2405 | 4696 | 2625 | 1.09 |
  | `p_pixel` | 10316 | 13238 | 10054 | 0.97 |
  | `p_sha` | 7534 | 12620 | 2439 | 0.32 |
  | `p_ldbl` | 113 | 46 | 35 | 0.31 |
  | `p_rotate` | 4007 | 5810 | 279 | 0.07 |
  | `p_bitfield` | 11087 | 11728 | 598 | 0.05 |
  | `p_simd` | 1571 | 9394 | 48 | 0.03 |

  The four floating-point primitives went from 0.07 to 0.18 of QEMU to 1.7 to 9.6 times
  it. QEMU does its floating point in software; `p_dbl_conv`, which is conversions, is
  where that costs it most. Eighteen of the twenty-three primitives are at QEMU's speed
  or past it; the five that are not are the ones nothing is translated for (x87,
  packed SSE, 16 bits, rotations whose flags are needed).

**Next.** The owner's to choose between: the kernel's memory through the TLB (task 5),
so that a Linux booted gets what programs without a kernel have (its boot is 271 → 180
host instructions for a guest instruction now, 25.3 s → 16.9 s); and the XMM registers
in host registers.

## E133: memory through the TLB, the stack and links in a machine (the JIT's fifth task; 2026-11-21)

A Linux booted gets little of the JIT: only blocks of register-only instructions (E120),
the boot 271 → 180 host instructions for a guest instruction, 25.3 s → 16.9 s, 3.9
instructions for each entry into a block. Everything since (memory, the stack, links,
the far way, SSE) is for a program without a kernel, where a guest address is an index
into memory. In a machine an address goes through the page tables, and the interpreter
keeps a TLB (E096): six tables, by the kind of access and the privilege level, where a
hit means allowed, with nothing more to check.

The owner's aim for this and what follows: the boot raced against QEMU's.

- **Hypothesis**: **with a load or store in a machine translated as a look-up in that
  TLB (a miss, an access across two pages, or a page outside memory leaves the block,
  and the interpreter walks the tables or faults), PUSH, POP, CALL and RET the same way,
  and links between blocks on one page, the boot runs four fifths of its instructions
  in blocks, ten or more for each entry, and costs under 100 host instructions for a
  guest instruction (180 now), under 10 seconds.**
- **What changed since last time**: a block is translated for the privilege level it was
  met at, and is not entered at another; FS and GS bases are given to a block.
- **Next move for each result**:
  - Under 100 → the far way in a machine (RET and jumps through an operand: the target
    looked up through the TLB for instructions), then the race against QEMU's machine
  - In blocks, entries still frequent → what ends the chains is counted (RET, jumps to
    another page, the string instructions, the kernel's own instructions)
  - `--jit-check` differs, or Linux does not boot → that, first
- **Cut-off**: the boot's host instructions and time; the suites with `--jit-check` and
  `--jit`; wrong builds.

**Result: the hypothesis holds on three of its four counts. The boot costs 89 host
instructions for a guest instruction (180), takes 8.3 seconds (16.9; 25.3 without the
JIT), and runs 17.8 instructions for each entry into a block; 78% of its instructions
are in blocks, just under the four fifths guessed.**

| The boot to the prompt, 1,524 million instructions | No JIT | E120 to E132 | Now |
|---|---:|---:|---:|
| Seconds | 25.3 | 16.9 | 8.3 |
| Host instructions for a guest instruction | 271 | 180 | 89 |
| Instructions in blocks | | 55% | 78% |
| Instructions for each entry into a block | | 3.9 | 17.8 |

- **A load or store in a machine** is the TLB's look-up in generated code: the entry
  for the address's page, in the table for this kind of access at the privilege level
  the block is translated for; its tag compared; the physical page with the offset put
  back. It leaves the block on a miss, on an access that may lie across two pages, and
  on a page not in memory: the interpreter then walks the tables, faults, or answers for
  what is not there. About eighteen host instructions for a load where a program
  without a kernel has five.
- **A block is for one privilege level**: it is not entered at another, and a link is
  made only between blocks of one level. Nothing in a block changes the level.
- **Links in a machine stay on the page**: there the target's physical address is known
  from the block's own. A jump to another page, a RET and a jump through an operand
  still go back to the interpreter: that is the far way, which needs the TLB for
  instructions, and is next.
- **FS's and GS's bases** are given to a block as it is entered; LEA takes none.
- **Linux boots** under `--jit` and under `--jit-check`, which compares every block of
  the boot with the same instructions interpreted, memory included; the disk, NetHack,
  the network and the frame buffer pass both ways.
- **Raced against QEMU's machine** (the owner's aim; `tools/boot_race.py`, QEMU 11.1.3
  with TCG, the same kernel and initramfs to the shell's prompt, the best of three):
  QEMU 2.65 s. g86m with the above 8.49 s, 3.2 times behind.
- **What the blocks handed back at was counted, and three things found.** Of 67 million
  entries in the boot, 22 million were left at a TEST of a byte with a constant and 16
  million at a MOV of 16 bits to memory, neither translated: the kernel's unpacking
  loop is made of them. Both are translated now (entries 67 → 27 million, the boot 89 →
  72 host instructions for a guest instruction). And 298 million instructions were
  still interpreted, of ordinary kinds, which no count of entries explained: **after
  the blocks are dropped (a write to a page that holds one: 99 times in the boot) the
  count of arrivals stood at its top, where it stays, and never came to the eighth
  again: what had been translated before a drop was interpreted for good.** It has
  been so since E122, where dropping came in; a program without a kernel seldom writes
  to its code's pages, so no primitive showed it. The count starts from nothing after
  a drop now.

| The boot to the prompt | No JIT | E132 | Memory through the TLB | With the three |
|---|---:|---:|---:|---:|
| Seconds (QEMU: 2.65) | 24.4 | 16.9 | 8.3 | 3.9 |
| Host instructions for a guest instruction | 271 | 180 | 89 | 40 |
| Instructions in blocks | | 55% | 78% | 93% |
| Instructions for each entry into a block | | 3.9 | 17.8 | 46 |

  1.5 times behind QEMU. Of 31 million entries left, half are jumps to another page
  (RET, CALL, jumps through an operand), which the far way in a machine would keep in
  generated code.

## E134: the boot raced against QEMU: what still sent it back to the interpreter (2026-11-21)

E133's next move, and the owner's race: QEMU's machine boots the same kernel and
initramfs to the prompt in 2.5 to 2.65 seconds; g86m stood at 3.9. (This card was written
after the first of its measurements, not before: the work went on from E133's counting
without a stop. What was guessed at each step is said with it.)

- **Hypothesis**: **half of the 31 million entries into blocks that are left are jumps to
  another page; with those looked up in generated code (the far way, through the TLB for
  instructions) the boot comes to QEMU's time.**
- **What changed since last time**: a jump's target on another page is found without
  leaving generated code, in a machine too.
- **Next move for each result**:
  - At QEMU's time → the wrong builds for everything since E133, with tests; then
    longer runs than a boot (NetHack's build in the guest)
  - Not there → what is interpreted is counted by address, not by kind
- **Cut-off**: `tools/boot_race.py`; the suites.

**Result: the far way alone did not do it (3.9 s → 3.7 s); counting by address found the
rest, and the boot now takes 2.4 seconds to QEMU's 2.5. Host instructions for a guest
instruction: 40 → 23; 95.6% of the boot's instructions run in blocks.**

| The boot to the prompt | Seconds | Host instructions for a guest instruction | In blocks | Entries into blocks |
|---|---:|---:|---:|---:|
| E133 | 3.9 | 40 | 93.3% | 31 million |
| The far way in a machine | 3.7 | 35 | 93.3% | 9 million |
| Only the written page's blocks dropped | 3.7 | 34 | 93.3% | 9 million |
| A page given up taken back | 2.4 | 23 | 95.6% | 9 million |
| QEMU 11.1.3, TCG | 2.5 | | | |

- **The far way in a machine**: the target's page through the TLB's table for fetching
  instructions at the block's privilege level, then the look-up of E123 by the physical
  address, and the block must be one made at that level. A jump or CALL to a known
  address on another page goes the same way. Entries fell from 31 to 9 million, and the
  time hardly moved: an entry costs about 440 host instructions, and 22 million of them
  are 10 billion of 61.
- **What the time was in** was the 100 million instructions still interpreted, at 280
  each. They were of ordinary kinds. Translating at the first arrival instead of the
  eighth changed nothing, so they were not code too cold to translate.
- **Dropping every block for a write to one page** (E122) is not needed in a machine,
  where a link never leaves its page and the far way reads the decode cache: only that
  page's blocks are forgotten. 166 drops of everything in the boot became none. It was
  not where the time was either.
- **Counted by address**, the instructions interpreted most were a RET at one address
  1.8 million times and three loops of a dozen plain instructions half a million times
  each: all on pages the decode cache had **given up** (E107: after 32 drops of a page
  it is not remembered from again, so that a page written and run in turns does not
  thrash). A kernel patches its own code as it starts, more than 32 times a page for
  some, and then runs it unchanged; and where the decode cache remembers nothing, no
  block can be. A page given up is now taken back when it has been run from 4,096 times
  with no write to it in between. 3.7 s → 2.4 s; the interpreter alone also gains (24.4
  → 23.2 s).
- **How rough the race is**: the best of three, the host's load 2.6 to 4; QEMU's time
  has its firmware loading the kernel in it, g86m's starts at the kernel's entry. 2.42
  against 2.53 is "the same".

- **Wrong builds of E133 and E134: 22 of 30 caught**, after `y_jit` was moved off the page
  its fault handler writes to (a page written that often is given up by the decode
  cache, and nothing on it was translated: the test's own loops were interpreted), and
  given a level-0 read at every fault, a loop that faults at level 3 round and round, two
  pages of code sharing an entry of the TLB; and `j_bytes` 16-bit MOV and byte TEST. Of
  the eight that pass, five only make the machine slower (a wrong index into the TLB, a
  count of arrivals not reset, a page given up not taken back, a far way that misses) and
  three are not reached by a test: a page outside memory, and a block or a link of one
  privilege level met at the other, which the TLB's own tables (one for each level) seem
  to keep from going wrong.

**Next.** The wrong builds for E133 and E134, with `y_jit` extended (code written while
its blocks are hot; a page given up, taken back, and written again). Then a run longer
than a boot.

## E135: NetHack built in the guest, raced against QEMU (2026-11-21)

The boot is 1.5 billion instructions and takes 2.4 seconds: no longer a measure. The
guest's own GCC building NetHack is about 430 billion (E119), four fifths of them a
program's and not the kernel's: the compiler, with the SSE moves it copies structures by
and the string instructions, neither of which a machine's blocks have. E119's build
stopped at a missing header; the disk has the kernel's headers now (`linux-headers`
7.0.0-r1, 2 MB, from Alpine, put into `images/disk64-dev.img`).

- **Hypothesis**: **with `--jit` the build that took the interpreter about two hours
  takes under fifteen minutes and ends with a NetHack that runs; QEMU does it in under
  five, so g86m is two to four times behind on a real program, and what the interpreter
  still runs in it is the SSE moves and the string instructions first.**
- **What changed since last time**: E119 was the interpreter, counting. This is the JIT
  as it is after E134, and QEMU on the same disk, kernel and initramfs.
- **Next move for each result**:
  - Two to four times behind, by SSE and strings → those two in a machine's blocks, in
    the order the count gives
  - Level with QEMU or ahead → said so; then what the next longer thing is
  - The build fails or its NetHack does not run under `--jit`, and does without → a
    wrong translation that no test has: found by turning parts of the JIT off, first
  - Something else is what the interpreter runs → that
- **Cut-off**: one build under each; the count of what g86m interpreted.

**Result: g86m took 3,561 seconds, QEMU 914: 3.9 times behind on a real program,
where the boot is level. The card's time was wrong by four, its ratio at its edge, and its
guess at the cause wrong.** Both builds made a NetHack that says its version, and both
stopped at the same last step (`doc/Guidebook`, which wants a typesetter the disk does not
have). The host was doing other work through both runs: the times are rough.

| NetHack built in the guest | QEMU 11.1.3 | g86m `--jit` |
|---|---:|---:|
| Seconds | 914 | 3,561 |
| Guest instructions | | 471.0 billion |
| In blocks | | 85.5% (the boot: 95.6%) |
| Instructions for each entry into a block | | 25 |
| Times the room for code filled and was emptied | | 1,493 |

**What the interpreter ran**, counted by a copy of g86m on three of NetHack's files
(23.9 billion instructions, 86% in blocks, 3.0 billion interpreted):

- **Not the SSE moves and the string instructions, as the card guessed**: together about a
  tenth of what was interpreted. 65% of it was in user mode, 35% the kernel's.
- **Not cold code.** Counted by how often each address was interpreted: 8% at addresses run
  fewer than 8 times, 37% at addresses interpreted more than 4,096 times. Hot code, of
  ordinary kinds (MOV, ALU, Jcc, the group 80h), outside blocks.
- **Why, read off the hottest addresses with their code and the decode cache beside them:**
  - **Behind an instruction that is not translated, the run is interpreted to the next
    jump.** The translator walks on past such an instruction to make the next block only
    if it knows the instruction's length, and for one of no kind that is not an SSE one
    (BT here: `bt rax, r15; jae`) it does not: the walk stops, and nothing behind it is a
    block until a jump lands there. The hottest interpreted address, a JAE behind a BT,
    ran 1.9 million times this way.
  - **Behind a way out the same**: a block left in its middle (a TLB miss, mostly) has the
    rest of its run interpreted to the next jump. 20% of what was interpreted.
  - **16-bit operations** (`shr cx, 6`) are not translated, and cut runs as BT does.
  - **The room for code fills**: 64 MB, emptied 70 times in three files and 1,493 times in
    the whole build. In a machine a page's blocks are forgotten when it is written, but
    their room is not given back; every emptying starts every count of arrivals from
    nothing.
- **The SSE instructions in a machine** (`0F 11`, `0F 6F`, `0F 29`, `0F 6E`): about a tenth.

**Next** (the owner's to choose): an instruction behind one interpreted, and behind a way
out, made an arrival, so that it becomes a block's head; the room for code made larger, or
given back; then BT, the 16-bit forms, and SSE in a machine. Each measured on the three
files (`RACE_SHORT=1 tools/build_race.py`, three minutes), then on the whole build against
QEMU.

## E136: real amd64 images under QEMU's user mode, before the optimizing goes on (2026-11-22)

The owner's order of 2026-11-22: beat QEMU on everything measured (the primitives, the boot,
the build in the guest) before the Docker backend (M11). Before starting, the owner asked
to look at what a Docker backend actually runs: a few real amd64 images, under QEMU's user
mode as OrbStack or Docker would run them. g64m cannot run them yet (it has three system
calls), so this measures QEMU's side only, and counts what instructions those programs
run. Images, by the owner's leave: `alpine:3.22`, `python:3.13-slim`, `node:22-alpine`,
`redis:alpine`, and Alpine's `build-base` for GCC, all for amd64 from Docker Hub.

- **Hypothesis**: **the instructions real images run are those the primitives and the
  in-guest build already show (ALU, MOV, Jcc, SSE moves), so E135's list of fixes keeps
  its order; Node, whose V8 writes code of its own all the time, is the one that differs,
  by code written while it runs.**
- **What changed since last time**: E135 measured a build in a machine (system mode). This
  is user mode, which is what a Docker backend is, on programs other than a compiler.
- **Next move for each result**:
  - The mix is what the list assumed → the list as it is, starting with the arrivals and
    the room for code
  - Something the list does not have is large (x87, packed SSE, AVX, 16-bit, string
    instructions, code written at run time) → that moves up the list
  - Under QEMU a workload is too slow to be worth racing on → it is left out of the races
- **Cut-off**: one timed run of each workload under QEMU and under Rosetta; one count of
  the instruction mix for each; this afternoon.

**Result: the hypothesis holds for the mix, and is wrong about Node. What real images run is
the integer code the list is already about; what is new is the race's own conditions: many
short processes, a CPU model QEMU gives the guest, and a second QEMU (OrbStack's) that is
not the same as the first.** (`tools/realimg/`; the Mac was not quiet, load about 4, so the
times are rough. Redis was timed only on OrbStack's path.)

Seconds for each workload: QEMU 11.0.3's user mode run by hand (`qemu-x86_64 -L`), OrbStack's
own path with its Rosetta setting off (QEMU through binfmt), with it on (Rosetta), and hal's
own CPU (an i7-3770K, in a chroot):

| Workload | QEMU 11.0.3 | OrbStack's QEMU | Rosetta | hal |
|---|---:|---:|---:|---:|
| busybox `sh`, a loop of 500,000 | 6.22 | 6.82 | 0.90 | 1.20 |
| busybox `seq` into `gzip`, 4 million lines | 5.56 | 7.58 | 2.82 | 1.12 |
| busybox `sha256sum`, 200 MB | 3.56 | 13.21 | 3.08 | 3.07 |
| Python 3.13 (`bench.py 4`: calls, strings, JSON, a sort, SHA-256) | 3.51 | 3.18 | 0.57 | 0.41 |
| Node 22 (`bench.js 4`, the same in JS) | 2.63 | 2.43 | 0.83 | 0.38 |
| GCC 14 `cc1 -O2` and `as` on the 23 primitives (46 processes) | 26.34 | 24.26 | 15.12 | 1.98 |
| Redis 7 `redis-benchmark` SET, GET, LPUSH, LRANGE_100, 20,000 each | segfault | 4.42 (LRANGE_100: 7,067 a second) | (33,613) | |

The instruction mix, sampled on hal (`perf record -e instructions:u`, one sample in 20,011,
every sample's instruction read from its binary; glibc told not to use AVX, Node's JIT told
the same), in percent of the samples:

| Class | sh | gzip | sha | Python | Node | GCC |
|---|---:|---:|---:|---:|---:|---:|
| Integer (MOV, ALU, LEA, MOVZX, shifts) | 66.9 | 79.4 | 81.7 | 77.6 | 70.1 | 73.2 |
| CALL, RET, JMP, PUSH, POP | 22.0 | 9.2 | 5.7 | 11.2 | 9.6 | 12.4 |
| Jcc | 5.6 | 2.8 | 2.1 | 3.0 | 8.0 | 5.5 |
| Jumps and calls through an operand | 0.8 | 0.6 | 2.0 | 1.7 | 0.6 | 0.5 |
| 16-bit destinations | 0.3 | 4.0 | | 0.2 | 2.0 | 1.8 |
| String instructions | 2.0 | 0.2 | 0.5 | 0.2 | 0.1 | 0.3 |
| SSE moves | 0.2 | 0.7 | | 0.7 | 0.6 | 3.0 |
| SSE packed | 0.1 | 0.1 | | 0.4 | 0.9 | 1.2 |
| SSE scalar, x87 | | 0.1, 1.6 | | 0.1 | | |
| Rotations | | | 5.2 | | | |
| SHRD, XCHG, CMPXCHG | 0.9 | 0.2 | 2.5 | 1.9 | 1.8 | |
| AVX (OpenSSL's and Node's own choice, not glibc's) | | | | 1.9 | 1.8 | |
| BT, CMOV/SETcc, MUL/DIV | 1.2 | 1.0 | 0.1 | 1.0 | 0.5 | 1.9 |
| Node: code its JIT wrote | | | | | 3.8 | |

What it says:

- **Real images run what the in-guest build ran.** Ordinary integer code and branches are 87
  to 94 percent everywhere. x87 (1.6% at most) and packed SSE (1.2% at most) are small; the
  primitives `p_ldbl` and `p_simd` measure things these programs hardly do.
- **The card's guess about Node was wrong.** V8's own code is 3.8% of Node's samples here;
  the rest is the `node` binary (its interpreter and builtins), ordinary integer code.
- **Many short processes.** The GCC workload is 46 processes. There Rosetta is only 1.7
  times QEMU (elsewhere it is 2 to 7), and hal is 12 times Rosetta: starting a process and
  translating its code once is a large part of the time. A Docker backend that is fast on a
  long loop and slow to start loses this.
- **The CPU the guest is shown decides its code.** Under QEMU's user mode glibc sees AVX2
  (`ld.so --list-diagnostics`: `AVX_Fast_Unaligned_Load=1`) and takes its AVX2 copies and
  string functions; OpenSSL and Node choose AVX on their own where they find it. g64m will
  run whatever its CPUID admits to; without AVX the same programs take their SSE2 paths,
  which g64m has.
- **There are two QEMUs.** OrbStack's binfmt QEMU is not the 11.0.3 run by hand: 3.7 times
  slower on `sha256sum`, 1.4 times on `gzip`, level elsewhere. The race is against the
  faster of the two. QEMU 11.0.3 run by hand dies on `redis-server` (signal 11) where
  OrbStack's runs it.
- **Small but present, and not yet translated**: SHRD (about 2% in Python and Node),
  rotations (5% in software SHA-256), string instructions (2% in the shell).

**Next.** The card's first branch: the list keeps its order, starting with the arrivals
behind untranslated instructions and ways out, and the room for code. Added to it from
here: SHLD/SHRD, the string instructions, and, for the Docker backend's sake, what it costs
to start a process (to be measured when M11 runs one). x87 and packed SSE stay on the list
for the primitives, last. OrbStack's Rosetta setting was turned off for the timing and
turned back on; the container that was running came back by its restart policy.

----
## E137: every interpreted instruction an arrival, and the room for code doubled (2026-11-22)

E135 read off the hottest interpreted addresses why 14% of the build ran outside blocks:
behind an instruction the translator cannot measure (BT, a 16-bit form) the walk stops, and
behind a way out of a block the rest of the run is interpreted, both to the next jump; and
the room for code (64 MB) filled 1,493 times in the build, each time starting every count of
arrivals from nothing. Arrivals are counted only where a jump lands (`jit_arrive`, from the
jumps, from a block's way out and from a new code page), so an instruction that is only ever
fallen into is never a block's head.

- **Hypothesis**: **counting an arrival at every instruction the interpreter runs from the
  decode cache (not only where jumps land) makes the instruction behind BT, behind a 16-bit
  operation or behind a way out a block's head at its eighth run, and on the three files of
  E135 the instructions interpreted fall from 3.0 billion (14%) to under 1.0 billion (4%);
  doubling the room to 128 MB (the reach of an AArch64 `b`) halves the flushes, 70 to about
  35, and the two together take a tenth or more off the time.**
- **What changed since last time**: E135's count. The arrival moves from the jumps to the
  run loop's hit on the decode cache (`exec64`), and `J_SIZE` goes to 128 MB.
- **Next move for each result**:
  - Interpreted under 4% and flushes halved → the whole build against QEMU (E135's
    914 s); then BT, the 16-bit forms, SHLD/SHRD and the string instructions in blocks
  - Interpreted still over 8% → the hottest interpreted addresses read again: another
    reason than the two found
  - Blocks or bytes translated grow by more than half → arrivals at every instruction
    translate cold code too: the threshold raised for fallen-into instructions, or the
    walk ahead cut
  - Slower → the count's cost on the interpreter's path, measured on `p_*` without `--jit`
- **Cut-off**: the short race (three files) three times at most; one whole build.

**Result: interpreted instructions fell from 13.9% to 7.9%, and the time by 3.5%: the
runs behind BT and the 16-bit forms are blocks now, but blocks of two or three
instructions, and entering a block costs about what interpreting those would.** The
three files, `RACE_SHORT=1 tools/build_race.py`, both builds `--jit --jit-stats`, CPU
time by `/usr/bin/time` (the host had other work; load 2.5 to 4):

| Three of NetHack's files | Before | E137 |
|---|---:|---:|
| CPU seconds (user) | 155.6 | 150.1 |
| Guest instructions | 23.89 billion | 23.89 billion |
| Interpreted | 3.32 billion (13.9%) | 1.88 billion (7.9%) |
| Entries into blocks | 876 million | 1,488 million |
| Instructions for each entry | 23.5 | 14.8 |
| Blocks translated | 10.2 million | 18.9 million |
| Code written in all | about 4.7 GB (73 × 64 MB) | 7.2 GB |
| Times the room filled | 73 (64 MB) | 53 (128 MB) |
| Links | 6.3 million | 8.6 million |

- **The first form counted every instruction the interpreter ran**, inside a block or
  not: interpreted 7.3%, but 21.9 million blocks and 1,598 million entries. A block that
  is refused or left for the time slice has its instructions interpreted one by one, and
  each became a head in its turn: the same block again from every offset, shorter. The form
  kept marks the instructions inside a block (`dc_cov`) and counts an arrival there only
  where a jump lands (`jit_land`, set by the jumps, by a block's way out and by a new code
  page), as before E137. Blocks 18.9 million, entries 1,488 million.
- **What the 1.44 billion instructions that moved into blocks cost**: 612 million more
  entries, 2.4 instructions an entry. The code behind a BT is `jae` and a block begins
  behind the jump; 16-bit forms cut the same way. An entry is a call into the room, the
  record settled and the arrival on the way back: on the order of a few interpreted
  instructions. So most of what was saved was spent entering.
- **The room**: 128 MB filled 53 times, 64 MB 73 times; the code written grew by half
  (the new heads, and the walk ahead from each). The room is not what limits here.
- **The hypothesis** was right about the heads and wrong about the gain. Not under 4%
  interpreted, not a tenth of the time.

**Next.** BT, the 16-bit forms and SHLD/SHRD translated, so that the runs they cut are one
block: the item next on the list, and what gives this change its worth. The counting of
arrivals stays as it is here.

----
## E138: BT, SHLD/SHRD and the 16-bit forms in blocks (2026-11-22)

E137 made the instruction behind a BT or a 16-bit operation a block's head, and found the
blocks so made two or three instructions long: the BT and the 16-bit forms cut every run,
and an entry into a block costs about what interpreting the two or three would. E135 read
`bt rax, r15; jae` off the hottest interpreted address and `shr cx, 6` beside it; E136
counted SHRD at 2% of Python and Node and 16-bit forms at 4% of gzip; `p_bitfield`'s loop
(0.05 of QEMU) has `shrw` and `sarw` in it.

- **Hypothesis**: **with BT, BTS, BTR and BTC on registers, SHLD and SHRD on registers,
  and the 16-bit forms of the ALU operations, CMP, TEST, the shifts by a constant, NOT,
  NEG and MOV of a constant translated, the three files of E137 run with under 4% of their
  instructions interpreted and under 1,000 million entries into blocks (from 7.9% and
  1,488 million), a tenth or more faster; and `p_bitfield` comes from 0.05 of QEMU to
  QEMU's neighbourhood.**
- **What changed since last time**: E137's arrivals. The translator gets the three
  families; the record of the flags gets BT's (CF alone) and the double shift's.
- **Next move for each result**:
  - Under 4% interpreted and a tenth faster → the whole build against QEMU, then the
    rotations with flags and the string instructions
  - Interpreted down but the time not → entries counted against instructions again; the
    hottest interpreted addresses read for the next cut
  - `p_bitfield` still far under QEMU → its block's listing: what else its loop has
  - A test fails under `--jit-check` → the form at fault, found by `--jit-off`
- **Cut-off**: the short race twice; the primitives once; one whole build if the short
  race says so.

**Result: `p_bitfield` went from 0.05 of QEMU to 0.73; the three files went from 7.9% to
6.8% interpreted and no faster, and a count of what is still interpreted says why: the SSE
moves in a machine, and cold code.** The short race as in E137 (CPU time; the host had
other work):

| Three of NetHack's files | E137 | E138 |
|---|---:|---:|
| CPU seconds (user) | 150.1 | 152.8 |
| Interpreted | 1.88 billion (7.9%) | 1.63 billion (6.8%) |
| Entries into blocks | 1,488 million | 1,279 million |
| Blocks translated | 18.9 million | 18.1 million |
| Times the room filled | 53 | 54 |

The primitives, the long forms of E131 under `--jit` on this host (QEMU's numbers from E131):

| | g64m, million instructions a second | QEMU | g64m / QEMU | In E131 |
|---|---:|---:|---:|---:|
| `p_bitfield` (`shrw`, `sarw` in its loop) | 9,100 | 12,448 | 0.73 | 0.05 |
| `p_shift` | 16,700 | 16,154 | 1.03 | 1.13 |
| `p_bytes` | 5,460 | 5,014 | 1.09 | 1.10 |
| `p_if` | 2,465 | 2,439 | 1.01 | 1.04 |

All 68 tests pass (`difftest64` 29 with the new `j_bits`, `prim64` 23, `systest64` 16).
`j_bits` goes round BT, BTS, BTR, BTC, SHLD, SHRD and the 16-bit forms fourteen times, with
its trace from hal; under `--jit` 1,026 of its 2,400 instructions run in blocks, against 666
with the three families turned off (`--jit-off` bits 52 to 54), in 20 blocks against 45.

**What the interpreter still runs** (a counting copy, `build/count_cov.py`: every
instruction run from the decode cache by its standing, over the three files; 1.64 billion
interpreted in all):

| | Instructions | Of the interpreted |
|---|---:|---:|
| SSE in a machine (`0F 6F` 140, `0F 11` 121, `0F 6E` 25, `0F 29` 23, PXOR 23, `0F 7E` 20, POR 16 million...) | 461 million | 28% |
| In no block, of a kind the translator takes (MOV 114, ALU 37, the group 80h 37, FFh 34, Jcc 24 million...): code run fewer than eight times | about 350 million | 21% |
| Run for the first time (not in the decode cache yet) | 139 million | 8% |
| Inside a block but interpreted: behind a way out, or a time slice's end | 140 million | 9% |
| A block's first instruction, the block left before it ran (a TLB miss on its load) | 87 million | 5% |
| Ports, CLI, STI, PUSHF, POPF, IRET, `rep insw` and `rep outsw` (the disk) | 54 million | 3% |
| Refused for the time slice | 6 million | |

- **BT, SHLD/SHRD and the 16-bit forms were not what cut the build's runs.** They are
  real in `p_bitfield` and in E136's gzip, Python and Node; the build's cutter is the SSE
  moves GCC copies structures with, which a machine's blocks do not have (E119 and E135
  said so; E137's counting of arrivals made them the head of every run behind them, hence
  the entries). One in four interpreted instructions is one, and nearly every one ends a
  block and costs an entry.
- **Cold code is the other half**: 490 million instructions run from one to seven times
  (29%). Each of GCC's processes runs its front, its parsing and its passes a few times
  over; the room's 54 flushes start every count again too.
- **The hypothesis** was right about `p_bitfield` and wrong about the three files: not
  under 4%, not faster.

**Next.** SSE in a machine (the moves, PXOR, POR, PAND, the shuffles), through the TLB as
the integer loads and stores are, with the operating system's leave (CR0.TS and EM) checked
on the way in: item six of the list, brought forward by this count. Then the cold code:
the threshold of eight, or the cost of a first run.

----
## E139: SSE in a machine (2026-11-22)

E138's count of what the interpreter still runs in the build: one in four instructions is
an SSE one in a machine, the moves GCC copies structures with (`0F 6F`, `0F 11`, `0F 29`,
`0F 6E`, `0F 7E`, `0F D6`) and PXOR, POR and PAND. All of them are translated in a program
without a kernel (E132), through `j_sse`; in a machine `j_one` refuses them, because the
operating system can take the unit away (CR0.TS, CR0.EM, CR4.OSFXSR) and the interpreter
looks at that before each. And each refused one ends a block: E137's arrivals make the
instruction behind it a head, so an SSE move costs an entry as well as its interpretation.

- **Hypothesis**: **with `j_sse` allowed in a machine, its memory operands through the TLB
  as the integer loads and stores are (`j_chk_n` knows 16 bytes already), and a way out
  before each SSE instruction when the unit is not to be used (a flag the block is given
  on entry, from CR0 and CR4), the three files run with under 5% of their instructions
  interpreted (from 6.8%) and under 900 million entries (from 1,279 million), a tenth
  faster; Linux boots under `--jit-check`, and the system tests pass, with a new one that
  moves through XMM registers with the unit taken away and given back.**
- **What changed since last time**: E138's count said which instructions. Nothing of the
  SSE translation changes; what changes is where it is allowed and the leave.
- **Next move for each result**:
  - Under 5% and a tenth faster → the whole build against QEMU (E135's 914 s); then the
    cold code (the threshold, the first run), or the packed forms the build has (`0F 73`,
    `0F 6C`, `0F 62`, `0F 70`)
  - Interpreted down, entries down, the time not → the entry's cost measured on its own
  - `--jit-check` differs in the boot → the leave or the TLB's path for 16 bytes, first
- **Cut-off**: the short race twice; one boot under `--jit-check`; the suites.

**Result: the three files run 14% faster (CPU 152.8 → 131.2 s), with 5.2% interpreted
(from 6.8%) and 1,148 million entries (from 1,279 million); and the boot under
`--jit-check` found a wrong translation of E138's, now taken out.** The short race as in
E137 and E138:

| Three of NetHack's files | E138 | E139 |
|---|---:|---:|
| CPU seconds (user) | 152.8 | 131.2 |
| Interpreted | 1.63 billion (6.8%) | 1.25 billion (5.2%) |
| Entries into blocks | 1,279 million | 1,148 million |
| Blocks translated | 18.1 million | 17.8 million |
| Times the room filled | 54 | 55 |

- **The change**: `j_one` no longer refuses `j_sse` in a machine. A block is given, on
  entry, whether the unit may be used (`jx[22]`: CR0.TS or EM set, or CR4.OSFXSR clear);
  before each SSE instruction two host instructions load that and leave the block if it is
  set, for the interpreter to fault as it did. The memory operands go through the TLB as
  the integer ones do (`j_chk_n` with 16 bytes). Nothing in `j_sse` itself changed.
- **The hypothesis** was right about the time (a tenth or more: 14%) and a little short
  on the counts: 5.2% interpreted for "under 5%", and the entries fell by 130 million,
  not by 380. An SSE instruction interpreted cost an entry behind it, so the entries
  should have fallen with the SSE count (461 million); that they fell by less says many
  of those SSE instructions were in runs cut by something else as well.
- **A wrong translation found**: `X64=--jit-check tools/systest64.sh` boots Linux with
  every block compared against the interpreter, and stopped at a block of the kernel's
  with `adc word [rsp + 0x10], 0` in it: E138's 16-bit forms let ADC and SBB through the
  narrow path, where `j_alu_n` has no carry and did an XOR. The byte forms had refused
  them (`!wide`); the 16-bit ones did not. They are refused now (`narrow`), and `j_bits`
  has 16-bit ADC and SBB with a carry going in. E138's PR was verified without the
  jit-check boot; it is part of the gate from here.
- **The new system test** `y_sse` moves through the XMM registers in a loop that is
  translated (11 SSE instructions in it; with SSE in a machine turned off, `--jit-off`
  bit 51, 320 fewer of its instructions run in blocks), then with CR0.TS set, when each
  must trap (48 traps counted, vector 7), then after CLTS. Its text is from hal under KVM.
  Its buffer had to go to a page of its own: a store to the loop's page dropped the
  page's entries, and the first form of the test translated nothing.

All suites pass: `difftest64` 29, `prim64` 23, `systest64` 17 three times (plain,
`--jit`, `--jit-check`), 104 lines of `ok`.

**Next.** The whole build against QEMU (E135: 3,561 s against 914), to see where the
three files' 14% puts it. Then the cold code (E138's count: 29% of what is interpreted
is run fewer than eight times), the packed forms the build has (`0F 73`, `0F 6C`,
`0F 62`, `0F 70`), BSF/BSR and CMPXCHG.

----
## E140: NetHack built in the guest, raced against QEMU again (2026-11-22)

E135 raced the whole build: g86m 3,561 s, QEMU 914 s, 3.9 times behind, 85.5% of the
instructions in blocks, 1,493 flushes. Since then: arrivals at every interpreted instruction
and a 128 MB room (E137), BT, SHLD/SHRD and the 16-bit forms (E138), SSE in a machine
(E139). On three of NetHack's files those took the CPU time from 155.6 s to 131.2 s (16%)
and the interpreted share from 13.9% to 5.2%.

- **Hypothesis**: **the whole build takes between 2,800 and 3,100 s under `--jit` (the
  three files' 16%, less what the whole build has that they do not: more processes, the
  linker, the install), with about 95% of its instructions in blocks and the flushes down
  to about 900 (twice the room, and fewer blocks); QEMU takes about 900 s again, so g64m
  is about three times behind.**
- **What changed since last time**: E137 to E139. The same kernel, initramfs, disk and
  command as E135 (`tools/build_race.py`), QEMU 11.1.3.
- **Next move for each result**:
  - Three times behind, 95% in blocks → the time is in the blocks' own code and the
    entries, not the interpreter: an entry's cost measured on its own, and the cold code
  - Still four times behind → what the whole build has that the three files do not,
    counted (the counting copy on the whole build)
  - Under 2,800 s → said so; the ratio stands
- **Cut-off**: one build under each. The host's load is noted beside the times.

**Result: g64m 2,870 s, QEMU 1,198 s: 2.4 times behind (E135: 3.9), with 94.9% of the
instructions in blocks; the flushes did not halve, because twice the code was written.**
The same disk, kernel and command as E135; both builds end at the same step
(`doc/Guidebook`, which wants a typesetter) with a NetHack that says its version. The host
had other work: load 13 as g64m started, 4 to 5 through most of it, 2 to 4 under QEMU.

| NetHack built in the guest | E135 | E140 |
|---|---:|---:|
| g64m `--jit`, seconds | 3,561 | **2,870** |
| QEMU 11.1.3, seconds | 914 | 1,198 |
| g64m / QEMU | 3.9 | 2.4 |
| Guest instructions | 471.0 billion | 471.1 billion |
| In blocks | 85.5% | 94.9% |
| Entries into blocks | 18.8 billion | 24.5 billion |
| Instructions for each entry | 25 | 18.2 |
| Blocks translated | | 375.5 million |
| Code written in all | about 95 GB (1,493 × 64 MB) | 157 GB |
| Times the room filled | 1,493 (64 MB) | 1,169 (128 MB) |

- **The hypothesis** was right about the time (2,800 to 3,100 s: 2,870) and the share in
  blocks (about 95%: 94.9%), wrong about the flushes (about 900: 1,169) and about QEMU's
  time (about 900: 1,198; the host, or E135's run was the lucky one). 2.4 times behind,
  not three: QEMU's slower run is half of that.
- **Where the time is now.** 95% of the instructions run in blocks, so the interpreter's
  5% can cost at most a fifth or so of the time even at 30 host instructions to one. What
  is left is the blocks' own code, the entries (24.5 billion: a block is entered every 18
  instructions, and an entry is on the order of a few dozen host instructions), and the
  translating: 157 GB of code written, 55 MB for every second of the build, 375 million
  blocks, each run from its room only until the next flush, 2.5 seconds later on average.
  After every flush the whole working set is interpreted eight times over and translated
  again. Neither the entries' nor the translator's share has been measured; both can be,
  with a clock around `jit_translate` and `jit_enter`.
- **Why twice the code.** E137's arrivals make a head of every instruction interpreted
  eight times, and `jit_translate` walks on from each head to make the next blocks on the
  page whether they will run or not. How much of what is translated is never entered has
  not been counted.

**Next.** Measure before cutting: a clock around the translator and the entry, and a count
of blocks never entered, on the three files; then whichever is largest: the room given back
by page (chunks, so a dropped page's blocks make room without a flush), the walk ahead
cut, or the entry made cheaper. The cold code (E138's 29% of the interpreted) behind that.

----
## E141: where the time goes with 95% in blocks: the translator, the entry, the blocks (2026-11-22)

E140: the whole build is 2.4 times behind QEMU with 94.9% of its instructions in blocks, a
block entered every 18 instructions, 157 GB of host code written (55 MB a second) and the
room flushed 1,169 times. The interpreter's share is bounded now; the rest is unmeasured.

- **Hypothesis**: **on the three files, the translator takes between a fifth and a third
  of the CPU time, the entries (the way in and out around a block, apart from the block's
  own code) between a tenth and a fifth, and at least a third of the blocks translated
  are never entered before the next flush (the walk ahead from every head).**
- **What changed since last time**: a measurement, no change to what is translated.
  `--jit-time`: a clock (`clock_gettime`, through `jit.c`) around `jit_translate`, around
  `jit_enter` and around the call into the block; a count of runs in each block's own
  code (five host instructions at its body's start), tallied at each flush and at the
  end into never run, run fewer than eight times, run more.
- **Next move for each result**:
  - The translator a fifth or more → the room given back by page (chunks), so a dropped
    page's blocks make room without a flush and the working set is not translated again
    every 2.5 seconds; and the walk ahead cut if a third of the blocks never run
  - The entries a fifth or more → the entry made cheaper (what it does in `jit_enter`,
    the settle of the record, the arrival), or fewer: the far way in a machine for more
    kinds of exit
  - Neither; the blocks' own code is the time → the hot blocks' listings against QEMU's,
    as E131 did for `p_loop`
- **Cut-off**: the short race once with the clocks, once with the clocks' own cost
  measured (`--jit-time` reads the clock a million times at the start and prints what one
  read costs).

**Result: the translator is 15% of the time and the entries' own cost about 6%; the walk
ahead is not the waste (0.2% of the blocks never run); the waste is the decode cache, which
kills four blocks in five by taking their first instruction's entry for another
instruction.** The short race with `--jit-time` (CPU 233 s, of which the clock's own cost,
22 ns a reading, four readings an entry, about 100 s; the shares below have it taken out):

| Three of NetHack's files, 131 s of CPU without the clocks | Seconds | Share |
|---|---:|---:|
| Translating (17.8 million blocks) | about 20 | 15% |
| The blocks' own code | about 48 | 36% |
| The entry around a block, apart from its code (1,145 million entries) | about 8 | 6% |
| The rest: the interpreter (5.2% of the instructions), the run loop, the devices | about 55 | 43% |

| Blocks, tallied at each flush and at the end | |
|---|---:|
| Never run | 7,892 (0.2%) |
| Run fewer than eight times | 697,664 (19%) |
| Run eight times or more | 2,972,217 (81%) |
| Translated in all | 17.8 million |

Of 17.8 million blocks translated, 3.7 million were there to be tallied: the rest had
gone before any flush. A counter at the place where the decode cache takes an entry for a
new instruction (`j_evicted`, in the stats line from here) says where: **14.7 million blocks
of 18.2 million lost their first instruction's entry to another instruction** (the cache
is 2^18 entries, direct-mapped by the physical address; GCC's code is far more
instructions than that), and a block whose entry is gone is translated again at its next
eighth arrival. That is the 157 GB of E140 and the flushes that did not halve.

**What a bigger cache buys** (DC_BITS 20, 2^20 entries, the same race; the binary is the
same 319,304 bytes, the arrays being zero-filled at the start; the memory is not):

| | 2^18 entries | 2^20 entries |
|---|---:|---:|
| CPU seconds (user) | 139.3 | 120.5 |
| Maximum resident set | 704 MB | 743 MB |
| Blocks translated | 18.2 million | 6.3 million |
| Blocks lost to the cache | 14.7 million | 3.5 million |
| Code written in all | 7.7 GB | 3.1 GB |
| Times the room filled | 57 | 22 |
| Entries into blocks | 1,166 million | 1,778 million |
| Interpreted | 5.3% | 4.0% |

- **The hypothesis** was right about the translator's share (a fifth to a third: 15%,
  a little under), right that the entries are small (under a tenth), and wrong about the
  walk ahead: the blocks are run; they are killed.
- **Entries rose by half with the bigger cache**: more instructions remembered, so more
  arrivals counted and more heads; the time fell all the same.
- **The owner's word: the program is not to grow.** A bigger cache is not the fix; the
  same cache made to keep a block's entry is: two ways to a set (a slot and its
  neighbour), the entry that is a block's first instruction kept and the other taken
  (E142).

**Next.** E142: the decode cache in two ways, at 2^18 entries; measured against the two
columns above.

----
## E142: the decode cache in two ways, so that a block keeps its first instruction's entry (2026-11-22)

E141: four blocks in five die when another instruction takes the decode cache's entry of
their first instruction (2^18 entries, direct-mapped by the physical address, and GCC has
more instructions than that); four times the entries made the three files 13% faster, but
the owner's word is that the program is not to grow.

- **Hypothesis**: **with each entry's slot paired with its neighbour (two ways to a set,
  one cache line), a new instruction taking the way that is no block's first instruction,
  and every look-up (the interpreter's, the translator's, the far way's in generated code,
  the drop of a page) trying both ways, the blocks lost to the cache fall from 14.7 million
  to under 3 million, the code written from 7.7 GB to under 4 GB, and the three files run
  about as fast as with four times the entries (120 s against 139 s), in the same memory.**
- **What changed since last time**: the cache's size stays 2^18. The way a new entry is
  placed and found changes; nothing is translated differently.
- **Next move for each result**:
  - Lost blocks under 3 million and the time near 120 s → the gate (all suites, the
    jit-check boot), the PR; then the cold code or the room given back by page
  - Lost blocks still over 6 million → two ways are not enough for GCC's code: the
    count of sets where both ways are blocks' heads, and four ways if it says so
  - The time not down with the blocks → the look-up's second probe costs on the
    interpreter's path: measured on `p_*` without `--jit`
- **Cut-off**: the short race twice; the primitives once.

**Result: the three files run in 113 s of CPU, from 139 (and 120 with four times the
entries), in the same memory; the blocks lost to the cache fell from 14.7 million to 3.8
million, the code written from 7.7 GB to 2.4 GB, the flushes from 57 to 17.** The short
race as in E141, the same host and hour:

| Three of NetHack's files | 2^18 entries, one way (E141) | 2^20, one way (E141) | 2^18, two ways |
|---|---:|---:|---:|
| CPU seconds (user) | 139.3 | 120.5 | **113.4** |
| Maximum resident set | 704 MB | 743 MB | 704 MB |
| Blocks translated | 18.2 million | 6.3 million | 6.0 million |
| Blocks lost to the cache | 14.7 million | 3.5 million | 3.8 million |
| Code written in all | 7.7 GB | 3.1 GB | 2.4 GB |
| Times the room filled | 57 | 22 | 17 |
| Entries into blocks | 1,166 million | 1,778 million | 995 million |
| Interpreted | 5.3% | 4.0% | 4.7% |

- **The hypothesis** was right about the code (under 4 GB: 2.4) and the time (about as
  fast as four times the entries: faster, 113 against 120), and a little short on the
  blocks lost (under 3 million: 3.8). Of the four times the entries' gain, two ways at the
  same size give all, and more: fewer entries into blocks (995 million against 1,778),
  since fewer instructions are remembered and fewer heads made.
- **What changed**: `dc_find` looks in a slot and its neighbour (one 64-byte line, the
  entries being 32 bytes); a new instruction takes the first way unless a block begins at
  the instruction there, then the second. The translator (`j_entry`, the block's head, the
  links' targets), the drop of a page and the far way in generated code (five more host
  instructions on a miss of the first way, in the user and the machine forms) look in
  both. The exits that wait for a block stay chained from the first way's slot.
- **Still lost: 3.8 million.** Two heads in one set, and a third instruction's entry
  wanted there: the second way is taken, head or not. Four ways would take more of these;
  whether they matter is for the count E141 can give.

All suites pass: `difftest64` 29, `prim64` 23, `systest64` 17 plain, with `--jit` and
with `--jit-check` (103 `ok`).

**Next.** The whole build against QEMU once more, then the cold code (E138: 29% of the
interpreted run fewer than eight times) and the room given back by page.

----
## E143: NetHack built in the guest, raced against QEMU after the two-way cache (2026-11-22)

E140: 2,870 s against QEMU's 1,198, 2.4 times behind, 157 GB of code written and the room
flushed 1,169 times. E142 found the cause of the code and took most of it away: on the three
files the blocks translated fell by two thirds, the code written to a third, the flushes to
a third, and the CPU time from 139 s to 113 s (19%).

- **Hypothesis**: **the whole build takes between 2,200 and 2,450 s under `--jit` (the
  three files' 19%, give or take the whole build's larger working set, which is where the
  cache's ways matter most), with the code written under 60 GB and the flushes under 450;
  QEMU takes 900 to 1,200 s, so g64m is about twice behind.**
- **What changed since last time**: E141's counters and E142's two ways. Same kernel,
  initramfs, disk and command (`tools/build_race.py`), QEMU 11.1.3.
- **Next move for each result**:
  - Under 2,450 s, flushes under 450 → the cold code (E138: 29% of the interpreted run
    fewer than eight times) and the room given back by page; the entry's share again
  - Flushes still over 700 → the whole build's working set does not fit two ways: the
    count of sets with two heads, and four ways
  - Under 2,200 s → said so; the ratio stands
- **Cut-off**: one build under each; the host's load beside the times.

**Result: g64m 2,441 s, QEMU 1,303 s: 1.9 times behind (E140: 2.4, E135: 3.9). The code
written fell to a third and the flushes to a third; but in the whole build three blocks in
five are still lost to the cache.** Both builds end at the same step with a NetHack that
says its version. Load 3 to 4 throughout.

| NetHack built in the guest | E135 | E140 | E143 |
|---|---:|---:|---:|
| g64m `--jit`, seconds | 3,561 | 2,870 | **2,441** |
| QEMU 11.1.3, seconds | 914 | 1,198 | 1,303 |
| g64m / QEMU | 3.9 | 2.4 | 1.9 |
| In blocks | 85.5% | 94.9% | 95.4% |
| Entries into blocks | 18.8 billion | 24.5 billion | 20.4 billion |
| Blocks translated | | 375.5 million | 125.0 million |
| Blocks lost to the cache | | | 78.6 million |
| Code written in all | about 95 GB | 157 GB | 50.6 GB |
| Times the room filled | 1,493 | 1,169 | 377 |

- **The hypothesis** held on the time (2,200 to 2,450 s: 2,441, at its edge), the code
  (under 60 GB) and the flushes (under 450); QEMU was outside what was guessed (900 to
  1,200 s: 1,303).
- **QEMU's time moves more than g64m's gains**: 914, 1,198 and 1,303 s on three
  afternoons for the same build. The ratio's fall from 2.4 to 1.9 is half g64m's 15% and
  half QEMU's 9% the other way. A wall clock on a host with other work is not a measure
  to hold a ratio to: the next race takes both programs' CPU time (`/usr/bin/time`), as
  the short race does for g64m.
- **Two ways are not enough for the whole build**: 78.6 million of 125 million blocks
  (63%) still lost their entry, against 3.8 of 6.0 million on the three files. The whole
  build has more code alive at once (the linker, `make`, the shell, more of GCC), and a
  set with two heads loses one at the third instruction's arrival.

**Next.** Why a block is left, counted by reason (a block is entered every 22
instructions: the entries are where QEMU, which chains its blocks, is ahead); and the
cache in four ways, with the count of what two ways lose. `tools/build_race.py` to report
CPU time for both.

----
## E144: where a block goes when it is left (2026-11-22)

E143: 20.4 billion entries into blocks for 450 billion instructions, a block left every 22
instructions; QEMU chains its blocks and g64m is 1.9 times behind. E141 put the entry's
own cost at 6% of the time, but every leaving also costs the interpreter's look-up, often
an instruction or a run interpreted, and a block not gone on to.

- **Hypothesis**: **of the times a block is left on the three files, more than half go to
  an address where no block will ever begin as things are (an instruction the translator
  refuses, hot or not), and of those the SSE and string instructions and the system's own
  (ports, CLI and STI, IRET, SYSCALL) are the larger part; fewer than a tenth are for the
  time slice.**
- **What changed since last time**: a count, with `--jit-why`: after each block, the
  standing of the address it went to (another page; not in the decode cache; in it and
  cold; in it, hot and no block, by kind; inside a block; a block's first instruction with
  or without time left for it).
- **Next move for each result**:
  - Refused instructions the larger part → those kinds translated, in the count's order
  - A block's first instruction, with time left, the larger part → links: why the exit
    was not one (the page, the table of waiting exits, the privilege level)
  - Another page the larger part → the far way's misses counted by their reason
  - Cold addresses the larger part → the threshold of eight
- **Cut-off**: the short race once with the count.

**Result: the hypothesis was wrong. Nine leavings in a hundred go to an instruction the
translator refuses; nearly half go to an address where a block already is, and was not
chained to.** The three files, `--jit --jit-why`, 1,026 million leavings (CPU 125.6 s):

| Where the block went | Millions | Share |
|---|---:|---:|
| On the page it was entered on: a block's first instruction, time left | 455 | 44% |
| On another page than the one entered on | 373 | 36% |
| – of those: a block there, of this level, time left | 178 | |
| – not in the TLB's table for fetches | 68 | |
| – not in the decode cache | 67 | |
| – hot and no block (a refused instruction) | 44 | |
| – cold | 16 | |
| On the page: hot and no block (a refused instruction) | 91 | 9% |
| On the page: not in the decode cache | 79 | 8% |
| On the page: cold (fewer than eight arrivals) | 26 | 3% |
| Inside a block; a block with no time left for it | 1.3; 1.0 | |

- **A block was there 633 million times in 1,026 million (62%)**, and the exit went out to
  the interpreter, which looked it up and entered it. ("Another page" is the page the
  chain of blocks was entered on, not the page of the block that left: a run of chained
  blocks goes through many, so most of those 178 million are exits on one page too.)
- **Why not chained: the table of waiting exits is full.** An exit to an address with no
  block yet is written into a table (`lk_site` and the rest, 65,536 entries) and made a
  branch when the block comes; the table is emptied only at a flush. With 6 million
  blocks between 17 flushes it fills in the first tenth of each stretch: **3.5 million of
  the 6 million blocks were translated with the table full**, and their exits to blocks
  not yet made stay ways out for good. When the room filled every few seconds (before
  E142) the table was emptied as often; with the flushes down to a third it is full most
  of the time.
- **A block that reads RFLAGS in memory, met with a record waiting**: 113 million (11%).
  Such a block (one that begins with INC, DEC, BT, a rotation, or a jump on flags set
  before it) refuses an entry from another block while a record is waiting, and the
  interpreter settles the record and enters it.
- **Refused instructions**: 135 million (13%): `0F 73` (the shifts of an XMM register by
  a constant) 12.7, PANDN 7.6, CMPXCHG 7.1, PUNPCKLQDQ 6.7, BSF 5.6, PSHUFD 3.0 million;
  the group FFh 10.6 million (INC and DEC of memory, PUSH of an operand); `rep stos` 3.4,
  CLI 2.0, OUT 1.8, `rep movs` 1.0 million.
- **Not in the TLB's table for fetches**: 68 million (7%); not in the decode cache or
  cold: 188 million (18%).

`tools/build_race.py` prints the CPU time of what it ran from here (E143).

**Next.** E145: the waiting exits kept without a table, in the room itself: four words
behind each such exit (the next in the chain, the address waited for, the level), so that
every exit can wait, however many, and the table and its limit go. Then the record
settled in a block's way in, the refused instructions in this count's order, and the cache
in four ways (E143).

----
## E145: the exits that wait for a block kept in the room itself, without a table (2026-11-22)

E144: 62% of the times a block is left, a block is where it went, not chained to: the table
of waiting exits (65,536 entries, emptied at a flush) is full for most of each stretch, and
3.5 of 6 million blocks were translated with it full.

- **Hypothesis**: **with each waiting exit carrying its own entry in the room (four words
  behind the branch: the next in the chain, the address waited for, the level), chained
  from `dc_wait` as before, every such exit is made a branch when its block comes; on the
  three files the leavings fall from 1,026 million to under 600 million, those that go to
  a block from 633 million to under 250 million (what is left being the blocks that read
  RFLAGS, and the exits on other pages, which the far way has), and the CPU time by a
  tenth or more (125 s to under 113 s).**
- **What changed since last time**: E144's count. The table (`lk_site`, `lk_to`,
  `lk_next`, `lk_cpl`: 1.4 MB) goes; a waiting exit takes 16 bytes of the room.
  When a block is made, the entries chained from its slot that wait for another address
  are chained again and not dropped, as they were.
- **Next move for each result**:
  - Leavings under 600 million and a tenth faster → the whole build with CPU times; then
    the record settled on the way into a block that reads RFLAGS (E144: 11%)
  - Leavings down, time not → the entry's cost was less than E141's bound says; the
    blocks' own code and the interpreter's share measured again
  - Leavings to a block still over 400 million → which exits: by the kind of exit
    (a jump's two sides, CALL, the end of a block), counted in `--jit-why`
- **Cut-off**: the short race with `--jit-why`, and once without; the gate.

**Result: the leavings fell from 1,026 million to 574 million, those that go to a block
from 633 million to 200 million, and the three files run in 104 s of CPU (E142: 113 s).**

| Three of NetHack's files | E144 (the table) | E145 (in the room) |
|---|---:|---:|
| CPU seconds with `--jit-why` | 125.6 | 106.3 |
| CPU seconds without | 113.4 (E142) | **104.0** |
| Leavings (entries into blocks) | 1,026 million | 574 million |
| – to a block on the page entered on | 455 million | 131 million |
| – to a block on another page | 178 million | 69 million |
| – of the two, a block that reads RFLAGS, a record waiting | 113 million | 117 million |
| – to a refused instruction | 135 million | 134 million |
| – not in the TLB's table for fetches | 68 million | 68 million |
| – not in the decode cache, or cold | 188 million | 167 million |
| Blocks translated | 6.0 million | 4.8 million |
| Times the room filled | 17 | 14 |

- **The hypothesis** held on the counts (leavings under 600 million: 574; to a block under
  250 million: 200) and nearly on the time: 8% against E142's race without the count,
  15% with the count on both sides, for "a tenth or more".
- **What changed**: an exit that waits for a block has four words behind its branch (the
  next in the chain, the address waited for in two, the level), 16 bytes of the room;
  `dc_wait` is the chain's head as before. When a block is made, the chain from its slot
  is read out of the room, the exits that waited for it are made branches, and those that
  wait for another address are chained again (they were dropped). The table and its
  1.4 MB are gone.
- **What is left of "a block was there"**: 200 million, of which 117 million are the
  blocks that read RFLAGS in memory, met with a record waiting. The other leavings are
  where they were: refused instructions 134 million, the TLB's table for fetches 68
  million, addresses not remembered or cold 167 million.

All suites pass: `difftest64` 29, `prim64` 23, `systest64` 17 plain, with `--jit` and
with `--jit-check` (103 `ok`).

**Next.** The record settled on the way into a block that reads RFLAGS (117 million, the
largest single reason now); the refused instructions in E144's order (`0F 73`, PANDN,
CMPXCHG, PUNPCKLQDQ, BSF, the group FFh forms); the whole build with CPU times.

----
## E146: the record settled in generated code on the way into a block that reads RFLAGS (2026-11-22)

E145 left 117 million leavings in 574 million at one reason: a block that reads RFLAGS in
memory (its first reader of the flags comes before any setter: a conditional jump, SETcc,
CMOV, ADC, INC, DEC, BT, a rotation) refuses an entry from another block while a record of
the flags is waiting, and the interpreter settles the record and enters it. A count of
which records wait there (`--jit-why`, the three files, 119 million): CMP 47.3 million,
TEST and AND 35.5, SHR 19.9, BT 4.5, SUB 3.6, ADD 3.0, DEC 2.0, MUL 0.9, OR 0.8, XOR 0.5.

- **Hypothesis**: **with a piece of generated code that makes RFLAGS in memory from a
  waiting record of ADD, SUB, CMP, AND, TEST, OR or XOR at any width (about 45 host
  instructions, called from such a block's way in; any other record goes out as before),
  three quarters of those leavings go (76% of the records are of these kinds): the
  leavings fall from 574 million to under 500 million and the CPU time by 3% or more.**
- **What changed since last time**: E145's count, and the count of records above. A
  block's way in is one instruction longer (28 bytes for 24); `jit_enter` takes RFLAGS
  back from what the block was given, since a block can now change it.
- **Next move for each result**:
  - Leavings under 500 million → the shifts' record settled the same way (SHR: 17%), if
    the time followed; then the refused instructions
  - Leavings down, time not → the cost of a leaving is small now; the interpreter's own
    share (cold code) and the blocks' code next
  - A test differs → the flag at fault: the new test reads all six behind a chained entry
- **Cut-off**: the short race with the count and without; the gate, with a new test
  (`j_settle`) whose blocks are entered from other blocks with a record of each kind and
  width waiting, and which reads every flag afterwards.

**Result: the leavings fell from 574 million to 482 million, those at a block that reads
RFLAGS with a record waiting from 117 million to 28 million, and the three files run in
100.3 s of CPU (E145: 104.0).**

| Three of NetHack's files | E145 | E146 |
|---|---:|---:|
| CPU seconds, without the count | 104.0 | **100.3** |
| Leavings (entries into blocks) | 574 million | 482 million |
| – a block that reads RFLAGS, a record waiting | 117 million | 28 million |
| – to a refused instruction | 134 million | 133 million |
| Blocks translated | 4.8 million | 4.4 million |

- **The hypothesis** held: under 500 million leavings (482), 3% or more of the time (3.6%).
- **What changed**: `j_settle_make` writes, once, about 60 host instructions behind the
  far way: from a record of ADD, SUB, CMP, AND, TEST, OR or XOR it shifts the operands up
  to the width's top, does the operation, and builds CF, OF, ZF, SF from the host's flags,
  AF from bit 4 of the three values and PF from the low byte, as `alu` does; RFLAGS in
  memory takes them, the record is cleared. Any other record (a carry or a count above
  the width, a shift, MUL, BT, INC and DEC) goes out as before. A block that reads RFLAGS
  has `cbz x7` over a `bl` to it in its way in, which is 28 bytes now for every block.
  `jit_enter` takes RFLAGS back from the block's copy. `--jit-off` bit 50 gives the old
  way in.
- **The new test** `j_settle`: 38 cases (the seven operations at four widths, and NEG,
  shifts, IMUL, BT and constants), each setting the flags twice from one pair of operands,
  once with PUSHFQ behind (the interpreter settles) and once with a jump into a block
  that begins with a conditional jump (the generated code settles, or for the kinds it
  does not take, the interpreter); the two RFLAGS are compared, over 24 rounds and eight
  pairs of operands. Under `--jit` the entries refused for a record fall from 602 to 60
  in it (the 60 being the kinds not taken). Its trace is from hal.
- **Left at that reason**: 28 million, the shifts' records (SHR was 17% of E146's count)
  and BT's.

All suites pass: `difftest64` 30, `prim64` 23, `systest64` 17 plain, with `--jit` and
with `--jit-check` (104 `ok`).

**Next.** The refused instructions, now the largest reason (133 million of 482): `0F 73`,
PANDN, CMPXCHG, PUNPCKLQDQ, BSF, the group FFh's forms, `rep stos`; then the addresses not
remembered or cold, the TLB's table for fetches, and the whole build with CPU times.

----
## E147: the instructions the translator refuses, in the count's order (2026-11-22)

E146 left the refused instructions as the largest single reason a block is left: 133
million of 482 million leavings on the three files. The count again, with the forms
(`--jit-why`, on the page entered on; about half as many again on other pages): the shifts
of an XMM register by a constant (`0F 73`) 12.5 million, PANDN 8.2, CMPXCHG 7.1, INC of
memory 5.5, PUNPCKLQDQ 5.4, BSF 5.1, DEC of memory 4.8, `rep stos` 3.3, PSHUFD 2.9, CLI
2.0, OUT 1.7, TEST of memory with a constant 1.5, PADDD 1.3, `rep movs` 1.1, PUNPCKLDQ 0.9,
XADD 0.9, PCMPEQB 0.7, BSWAP 0.65.

- **Hypothesis**: **with the packed forms (`0F 73`'s four shifts, PANDN, the PUNPCKL and
  PUNPCKH family, PSHUFD, PADD and PSUB, PCMPEQ and PCMPGT), BSF and BSR, BSWAP, CMPXCHG,
  INC and DEC of memory and TEST of memory with a constant translated, the leavings to a
  refused instruction fall from 133 million to under 75 million, all leavings from 482
  million to under 430 million, and the CPU time by 3% or more.**
- **What changed since last time**: E146's count. Each form is one to four host
  instructions (NEON for the packed ones, RBIT and CLZ, REV, a CMP's record and two
  CSELs); BSF and BSR get a record of their own (52h, 53h).
- **Next move for each result**:
  - As guessed → the string instructions (`rep stos`, `rep movs`: 4.4 million), the
    system's own (CLI, STI, OUT, PUSHF), then the cold code and the whole build
  - Leavings down, time not → as E146's second line: the leaving is cheap now
  - A test fails → that form, by `--jit-off` bit 49 (the integer forms) or 57 (SSE)
- **Cut-off**: the short race with the count and without; the gate, with two new tests.

**Result: the leavings to a refused instruction fell from 133 million to 50 million, all
leavings from 482 million to 395 million, the CPU time from 100.3 s to 97.7 s; and the
longer blocks brought out a wrong decision about dead flags that had been there since
E128, which no suite could see.**

| Three of NetHack's files | E146 | E147 |
|---|---:|---:|
| CPU seconds, without the count | 100.3 | **97.7** |
| Leavings (entries into blocks) | 482 million | 395 million |
| – to a refused instruction | 133 million | 50 million |
| Interpreted | 4.5% | 4.2% |

- **The hypothesis** held on the counts (refused under 75 million: 50; leavings under 430
  million: 395) and fell a little short on the time (2.6% for "3% or more").
- **What is translated now**: the shifts of an XMM register by a constant (`0F 73`: USHR,
  SHL, and EXT against a zero register for the byte shifts), PANDN, the PUNPCKL and
  PUNPCKH family (ZIP1, ZIP2), PSHUFD (four moves of an element), PADD, PSUB, PCMPEQ,
  PCMPGT; BSF and BSR (RBIT and CLZ; the register left as it was for zero; records 52h
  and 53h) with F3h in front or not; BSWAP (REV); CMPXCHG of 32 and 64 bits, of a register
  or memory (a CMP's record, two CSELs); INC and DEC of memory; TEST of memory with a
  constant. `--jit-off` bit 49 turns the integer forms off, 43 to 48 the packed groups.
- **The first race failed: GCC stopped inside the guest with an internal error**
  (`ira_color`), 17 seconds in, with every suite passing and the build passing under
  `--jit-check`. Found by turning things off: SSE (bit 57) → `0F 73` → the byte shifts;
  the same failure with the byte shift made by other code, so not its code; passing with
  the dead-flags analysis off (bit 60) or blocks ended at jumps (bit 61); passing with the
  analysis off for TEST alone; then one TEST found by a hash of its bytes, following the
  failing half sixteen times. The block:

      xor ecx, ecx / tzcnt rcx, rdx / shr rdx, cl / ... / movdqu xmm0, [rsi+0x28]
      movdqa xmm1, xmm0 / psrldq xmm1, 8 / por xmm0, xmm1 / movq rax, xmm0
      test rax, rax / je ...

  A shift by CL makes its record only if the count is not zero, and marks the block
  (`j_dyn`: whether the record was set was decided as it ran), which also says the
  host's flags are of no use to a jump. The TEST's flags are read by the JE alone (dead on
  both of its sides), so no record is made for it and the JE is to use the host's flags:
  but the path that leaves the record out did not clear `j_dyn`, the JE found no
  condition, the block ended in front of it, and the JE was interpreted on the record
  that was there, the shift's. Until now a PSRLDQ or a BSF between the shift and the TEST
  ended the block and hid it. Cleared now wherever a record is left out and the host's
  flags are the instruction's own (`j_rec_w`, `j_rec_alu`, BT, COMIS).
- **Why no suite saw it**: `--jit-check` does not compare RFLAGS where a block leaves
  them stale, which is exactly where the analysis has decided; a wrong decision passes it
  by construction. `j_misc` has the case now (a TEST behind a shift by CL and an SSE
  instruction, its jump taken in the first round so that both sides are known): it fails
  under `--jit` without the fix and passes with it. The build race's `make-rc` is part of
  the gate from here.
- The guard on the table of ways out is 12 free entries for an instruction, not 4 (an SSE
  store in a machine takes five).

All suites pass: `difftest64` 32 (with `x_packed` and `j_misc`, traces from hal),
`prim64` 23, `systest64` 17 plain, with `--jit` and with `--jit-check` (106 `ok`); the
short race ends with `make-rc=0`.

**Next.** The whole build with CPU times; then what is left of the leavings: addresses
not remembered or cold (145 million), the TLB's table for fetches (68 million), a block
that was there (116 million: the shifts' records, and exits on other pages), the string
instructions and the system's own.

----
## E148: NetHack built in the guest, raced against QEMU with CPU times (2026-11-23)

E143: 2,441 s against QEMU's 1,303 s by the wall clock, 1.9 times behind, with QEMU's own
time moving by a third from one afternoon to the next. Since then: the waiting exits kept
in the room (E145), the record settled on the way into a block (E146), the refused
instructions (E147). On the three files the CPU time went from 113.4 s (E142) to 97.7 s
(14%) and the leavings from 1,026 million to 395 million.

- **Hypothesis**: **the whole build takes between 2,000 and 2,200 s of CPU under `--jit`
  (E143's 2,441 s of wall clock less the three files' 14%), with under 12 billion entries
  into blocks (from 20.4 billion) and under 300 flushes (from 377); QEMU takes between 900
  and 1,300 s of CPU, so g64m is between 1.6 and 2.2 times behind.**
- **What changed since last time**: E145 to E147, and the measure: `tools/build_race.py`
  prints the CPU time of what it ran (user and system), which a loaded host moves less.
- **Next move for each result**:
  - As guessed → the leavings that are left (addresses not remembered or cold, the TLB's
    table for fetches), then the blocks' own code (36% of the time in E141)
  - QEMU's CPU time far from its wall clock (its other threads) → both given, and the
    ratio by CPU time held to from here
  - The build fails → E147's way: the bits, the kinds, the hash
- **Cut-off**: one build under each; `make-rc` and the NetHack's version in both.

**Result: g64m 1,987 s of CPU, QEMU 973 s: 2.0 times behind. The entries into blocks fell
from 20.4 billion to 8.2 billion.** Both builds end at the same step (`doc/Guidebook`,
`make-rc=2` as always) with a NetHack that says its version. Load 35 as g64m started (the
host just woken), 3 to 7 after the first minutes.

| NetHack built in the guest | E135 | E143 | E148 |
|---|---:|---:|---:|
| g64m `--jit`, wall clock | 3,561 s | 2,441 s | 2,021 s |
| g64m `--jit`, CPU (user) | | | **1,987 s** |
| QEMU 11.1.3, wall clock | 914 s | 1,303 s | 994 s |
| QEMU 11.1.3, CPU (user) | | | **973 s** |
| g64m / QEMU | 3.9 | 1.9 | **2.0** (CPU) |
| In blocks | 85.5% | 95.4% | 96.0% |
| Entries into blocks | 18.8 billion | 20.4 billion | 8.2 billion |
| Blocks translated | | 125.0 million | 91.2 million |
| Blocks lost to the cache | | 78.6 million | 54.4 million |
| Code written in all | about 95 GB | 50.6 GB | 39.4 GB |
| Times the room filled | 1,493 | 377 | 293 |

- **The hypothesis** held: 1,987 s for "2,000 to 2,200" (a little under), 8.2 billion
  entries for "under 12 billion", 293 flushes for "under 300", QEMU's 973 s for "900 to
  1,300", twice behind for "1.6 to 2.2".
- **QEMU's CPU time is its wall clock** (973 s and 994 s): one thread does the work. Its
  1,198 s and 1,303 s of E140 and E143 were the host's load; by CPU the ratio was never
  1.9. Against E135's first race (3.9 times, both by the wall clock on a quieter hour)
  g64m has gone from 3,561 s to 2,021 s and the distance from 3.9 to 2.0.
- **Three blocks in five are still lost to the cache** in the whole build (54.4 of 91.2
  million), and translated again.

**Next.** The owner's proposal: look at how QEMU runs the same build (its blocks, its
chaining, where its host time goes) and bring over what makes the difference; and the
cache in four ways.

----
## E149: how QEMU runs the same build: its blocks and where its host time goes (2026-11-23)

The owner's proposal after E148 (g64m twice behind QEMU on the build): look at QEMU doing
the same work and bring over what makes the difference. E131 did this for one loop of a
primitive (QEMU's host code read beside g64m's: g64m ahead there, registers in host
registers against QEMU's loads and stores). The build is a different thing: many processes,
much code run a few times, a kernel.

- **Hypothesis**: **on the three files QEMU translates far fewer blocks than g64m's 4.4
  million (under one million: it translates a block once, at its first run, and keeps it:
  its cache is by the block's address, with no eighth arrival and no entry to lose), chains
  nearly all of them, and spends under a tenth of its host time translating and under a
  tenth looking blocks up; g64m by the same profile spends a third or more outside
  generated code (the interpreter for cold code, the run loop, the look-up on each entry,
  translating again).**
- **What changed since last time**: a measurement of the other program. QEMU's monitor
  (`info jit`) for its counts; the host's sampler (`sample`, 20 s in the middle of the
  build) for where each program's time is, by function.
- **Next move for each result**:
  - QEMU translates once and keeps: g64m's eight arrivals and its lost entries are the
    difference → translate at the first run (or the second), blocks kept apart from the
    decode cache's entries so that none is lost
  - QEMU's time is in generated code as g64m's is → the blocks' own code compared again
    (the memory access's inline path, the flags), as E131 did
  - QEMU's look-up for a jump through a register is a small table by address → the same
    for g64m's far way
- **Cut-off**: one run of each program with the counts and the sample.

**Result: QEMU builds the three files in 65 s to g64m's 98 s, translates a tenth as many
blocks and never throws one away; and its generated code, taken together, is faster than
g64m's: 45 s against 62 s.** `tools/build_look.py`: the same three files, QEMU 11.1.3's
monitor (`info jit`) at the end, and the host's sampler on each program for 20 s in the
middle of the build (20,000 samples of the thread that does the work; leaves in generated
code are what is left when the named functions are taken off).

| QEMU's own counts (`info jit`) | |
|---|---:|
| Blocks translated (TB count) | 438,153 |
| Flushes of its room (1 GB; 283 MB used) | 0 |
| A block: guest bytes, host bytes | 18 (about five instructions), 309 |
| Blocks with a chained jump | 54% (two jumps: 45%) |
| Blocks invalidated | 21,822 |

g64m on the same work: 4.3 million blocks translated, 13 flushes, 2.6 million blocks lost
to the decode cache.

| Where the host time goes | QEMU (65 s) | g64m (98 s) |
|---|---:|---:|
| Generated code | 69%: 45 s | 63%: 62 s |
| Finding the next block (`helper_lookup_tb_ptr` and its hash table; g64m: `exec64`, the run loop) | 26%: 17 s | 12%: 12 s |
| Interpreting (g64m only: `exec64_rest`, `exec64_miss`, `modrm`, `alu`, ...) | | 14%: 14 s |
| Translating (g64m: with the flushes' clearing and the writes into the room) | 1.4%: 0.9 s | 7.5%: 7 s |
| The memory's slow path (page walks, TLB fills) | 2.4%: 1.6 s | 3%: 3 s |
| Other helpers (QEMU: the flags, the XMM helpers) | 1.1% | |

- **The hypothesis** held on QEMU's blocks (under one million: 438 thousand, a tenth of
  g64m's) and its translating (1.4%), and on g64m's share outside generated code (37%).
  It was wrong about QEMU's look-up, which is a quarter of its time (guessed under a
  tenth): QEMU leaves its generated code for every jump through a register or to another
  page, and g64m's far way, which stays in generated code, is ahead there.
- **What was not guessed: g64m's generated code is the larger part of the distance.**
  17 s of the 33 s between the two programs are in generated code, where E131 found g64m
  ahead on a loop of registers. The build is not that loop: it is loads and stores. In a
  machine g64m's inline path for a load is about 17 host instructions (the TLB's tag, the
  page crossing, the page's place in memory, each with its own way out, and two loads of
  the tables' addresses) and for a store about 24 (the same and the look for remembered
  instructions on the page); QEMU's is about seven (one comparison that covers the tag
  and the crossing, and an addend). And the XMM registers are loaded and stored around
  every SSE instruction.
- **The rest of the distance** is what QEMU does not have: an interpreter and the way to
  it (26 s in g64m, 17 s of look-up in QEMU), and translating again what was lost (7 s
  against 1 s).

**Next**, by size: (1) the memory access in a block made short: an addend in the TLB's
entry, one comparison for the tag and the crossing, pages that are not plain memory and
pages that hold remembered instructions kept out of the tables that the blocks read, the
tables' addresses in host registers (E150); (2) blocks kept when the decode cache's entry
goes, and translating earlier than the eighth arrival; (3) four ways.

----
## E150: the load and the store in a machine's block made short (2026-11-23)

E149: half of what g64m is behind QEMU on the build is in generated code, 62 s against
45 s on the three files. A load in a machine's block is about 17 host instructions before
the load itself, a store about 24: the page's entry found, its tag compared, the access
kept from crossing a page, the tables' two addresses loaded from the context, the
physical page put together with the offset, the page's place in memory checked, and for a
store the two pages looked up among those that hold remembered instructions. QEMU's is
about seven.

- **Hypothesis**: **with the TLB's entry holding the difference between the physical and
  the linear page (an addend, added to the address), one comparison of the entry's tag
  with the page of the access's last byte (which fails for a miss and for a crossing
  alike), the tables' address in a host register, and the tables the blocks read never
  holding a page that is not plain memory nor, for writes, a page with remembered
  instructions (so neither is checked in the block), a load is 9 host instructions and a
  store 9; the three files' CPU time falls from 97.7 s to under 88 s (a tenth), all in
  generated code.**
- **What changed since last time**: E149's profile. `tlb_phys` becomes an addend behind
  the tags in one array; a page that is not plain memory, or (for a write) holds
  remembered instructions, is kept in a small table of its own that only the walk looks
  at; a page that comes to hold remembered instructions is taken out of the write tables.
- **Next move for each result**:
  - A tenth or more → the XMM registers kept in host registers across a block's SSE
    instructions (the other part of E149's 17 s), then the interpreter's share
  - Under 5% → the generated code's time is not the memory's checks: a block's listing
    from the build read beside QEMU's, as E131 did
  - Slower without `--jit` → the walk's look at the small table costs: measured on the
    boot without the JIT
- **Cut-off**: the short race (with `make-rc`), the boot's time with and without the
  JIT, the gate.

**Result: the three files run in 92.5 s of CPU, from 97.7 s (5.3%), and the code written
is half: 1.0 GB for 1.9 GB.** Half of what was guessed for the time.

| Three of NetHack's files | E147 | E150 |
|---|---:|---:|
| CPU seconds | 97.7 | **92.5** |
| Code written in all | 1.88 GB | 1.00 GB |
| Times the room filled | 14 | 7 |
| Blocks translated | 4.38 million | 4.06 million |
| Entries into blocks | 395 million | 427 million |

- **The hypothesis** was right about the instructions (a load's way is 9 host
  instructions, 8 for a byte, one more in a table that is not the first; it was 17, and a
  store's 24) and short on the time: 5.3% for "a tenth". The blocks are half as long in
  bytes; the time in them did not halve, the checks that went being ones that were never
  taken and cost little beside the load they stand in front of.
- **What changed**: `tlb_tag` holds the tags and, `TLB_ADD` entries on, the addend
  (physical page less linear page); `xlate` adds it. A page that is not plain memory, or
  for a write one that holds remembered instructions, goes into a table of 64 entries for
  each kind (`sp_tag`, `sp_add`) that only `walk` looks at, and is looked at again on each
  use; a page that comes to hold remembered instructions is taken out of the tables for
  writes (`tlb_unwrite`, from where `dc_mark` is set). In a block: UBFX for the index, the
  tag loaded through x28, the page of the access's last byte compared with it by one EOR
  with a shift, one way out, the addend loaded and added. The far way adds the addend too.
- **Without the JIT** the boot to the shell is where it was (24 s in the console test).

All suites pass: `difftest64` 32, `prim64` 23, `systest64` 17 plain, with `--jit` and
with `--jit-check` (106 `ok`); the short race ends with `make-rc=0`.

**Next.** The other things E149's profile has on g64m's side, by size: the interpreter
and its dispatch (26 s then: cold code translated sooner, a block kept when its decode
entry goes), the XMM registers loaded and stored around every SSE instruction, the
translating itself (7 s then, less now with half the code).

----
## E151: a block made sooner than the eighth arrival (2026-11-23)

E149: QEMU has no interpreter; g64m spent 26 s of 98 in its interpreter and on the way to
it, on the three files. A block is made at the eighth arrival at an instruction (`J_HOT`,
E120's number, set when the translator was new and a block cost more than it does). The
translator reads the decode cache's entries, so the first run of an instruction is the
interpreter's whatever the number; the second is the soonest a block can be made. E138
counted 21% of the interpreted instructions as run fewer than eight times, and every
flush and every block lost to the cache (three in four) costs seven runs of its
instructions before it is a block again.

- **Hypothesis**: **with a block made at the second arrival the three files' interpreted
  instructions fall from 4.3% to under 3% and the CPU time from 92.5 s to under 88 s; the
  blocks translated grow by less than half (most code that runs twice runs eight times).**
- **What changed since last time**: `--jit-hot N` sets the number (8 as it is); the race
  at 2, 3, 4 and 8.
- **Next move for each result**:
  - Faster at 2, 3 or 4 → that number the default; then the blocks kept when their
    entry goes (four ways)
  - Slower at every smaller number → translating costs more than seven interpreted
    runs: the translator's own time, read from the sampler
  - The blocks translated more than double → cold code is most of the code: the
    number stays, and the cache's ways first
- **Cut-off**: four short races; the gate for the number chosen.

**Result: sooner is not faster, and the interpreted instructions are not cold code: a third
of them are instructions whose entry the decode cache has given up.** The three files,
CPU seconds (the host's own spread between runs is about 3%):

| A block at arrival | CPU seconds | Blocks translated | Code written | Interpreted |
|---|---:|---:|---:|---:|
| 1 | 100.8 | | | |
| 2 | 92.2 | 7.6 million | 1.79 GB | 0.99 billion |
| 4 | 89.6 | 5.7 million | 1.38 GB | 0.99 billion |
| 8 (as it is) | 89.2 | 4.1 million | 1.01 GB | 1.04 billion |

- **The hypothesis was wrong on each count.** The interpreted instructions hardly move
  with the number (1.04 to 0.99 billion, for "4.3% to under 3%"); the blocks nearly double
  at 2 (for "less than half more"); the time is no better and at 1 is a tenth worse. The
  number stays 8; `--jit-hot N` stays as an option.
- **What the interpreter runs** (`--jit-why` counts each instruction it runs by its
  standing; 1,130 million through the run loop, of which 428 million are entries into
  blocks; the rest of the 1,032 million "interpreted" are repetitions of string
  instructions):

| | Millions |
|---|---:|
| Not in the decode cache (a first run, or an entry given up) | 373 |
| A block's first instruction, the block refused or left at once | about 103 |
| In no block, and cold | 99 |
| In no block, hot: refused (ports and the rest 48, RDTSC 4, BT of memory 2, ...) | 89 |
| Inside a block | 38 |

- **The cache is what the interpreter runs for.** 373 million instructions were not in
  the decode cache when run; the program has about 0.4 million blocks' worth of code (QEMU's
  count, E149), so nearly all of those are entries given up and met again: decoded again,
  their arrivals counted from nothing again, so that an instruction whose entry does not
  last eight arrivals is never a block's first. The "cold" 99 million are the same
  instructions on their way. E141 saw the same from the blocks' side (three in four lost).

**Next.** E152: which entry the cache gives up. An entry of an instruction inside a block
is of no more use once the block is made (the translator read it; the interpreter runs it
only when a block is left in its middle), and most entries are such; they go first, then
the coldest, and a block's first only when the other way holds one too.

----
## E152: which entry the decode cache gives up (2026-11-23)

E151: 373 million of the instructions the interpreter runs on the three files are not in
the decode cache when they come, nearly all of them entries given up and met again; three
blocks in four are lost the same way (E141, E148). The cache is 2^18 entries in sets of
two ways (E142); a new instruction takes the first way unless a block begins there, then
the second, whatever the second holds.

- **Hypothesis**: **with the way to give up chosen by what it holds (an empty one; else
  one whose instruction is inside a block; else the one with fewer arrivals; a block's
  first instruction only when both ways hold one), the instructions run from outside the
  cache fall from 373 million to under 150 million, the blocks lost to the cache from 3.0
  million to under 1.5 million, and the CPU time by 4% or more (89 s to under 86 s), in the
  same memory.**
- **What changed since last time**: E151's count. Only the choice of the way, on a miss.
- **Next move for each result**:
  - As guessed → four ways with the same choice, if the count says sets of two still
    lose; then the whole build
  - Misses not under 250 million → the code alive at once does not fit 2^18 entries
    however chosen: the size (2^19, 16 MB more) put to the owner with this count
  - More entries into blocks cut short (a block needs the entries of its instructions)
    → the blocks' lengths counted before and after
- **Cut-off**: the short race with the count and without; the gate.

**Result: choosing the way differently made it worse; the size is what is short. With four
times the entries the three files run in 68.6 s of CPU, from about 90 s, beside QEMU's
65 s.**

The choice of the way (an empty one, one inside a block, the colder; a block's first only
when both are): the instructions run from outside the cache rose from 373 to 443 million,
the blocks lost stayed at 3.0 million, the CPU time rose (89.2 to 93.6 s). Taken back. The
blocks lost did not move because both ways of a set hold a block's first instruction: about
580 thousand blocks are made between two flushes, and the cache has 262 thousand entries
for them and for every other instruction.

The size, with E142's choice as it was, the far way made to follow `DC_BITS` (it was
written for 2^18 and went out of use at any other size, E141's 2^20 among them), the same
binary size at each (319,912 bytes):

| Entries | CPU seconds | Not in the cache | Blocks translated | Blocks lost | Code written | Flushes | Maximum resident set |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2^18 (as it is) | 93.7 (89 to 92 without the count) | 386 million | 4.07 million | 2.96 million | 1.00 GB | 7 | 575 MB |
| 2^19 | 77.1 (76.0 without) | 237 million | 2.26 million | 1.20 million | 0.60 GB | 4 | 560 MB |
| 2^20 | 68.8 (68.6 without) | 113 million | 1.21 million | 0.41 million | 0.35 GB | 2 | 630 MB |
| 2^21 | 66.9 | 94 million | 0.74 million | 0.15 million | 0.24 GB | 1 | 535 MB |

- **The hypothesis** was wrong: misses not under 150 million by the choice (443 million),
  no blocks saved, slower.
- **Each doubling to 2^20 takes a seventh or more off the time**; 2^21 adds little. An
  entry with what stands beside it is 50 bytes (the entry 32, the arrays beside it 18):
  13 MB at 2^18, 26 MB at 2^19, 52 MB at 2^20, 105 MB at 2^21, zero-filled and touched as
  used. The resident set does not follow it (fewer flushes touch less of the room for
  code): 575, 560, 630, 535 MB.
- **The owner's word (E141) was that the program is not to grow**; the size is the
  owner's to choose with these numbers. Until then it stays 2^18.

**Next.** The owner's choice of the size; then the gate at that size, and the whole
build against QEMU.

**The owner's choice (2026-11-23): 2^20 entries**, after asking what it costs (39 MB more
resident and 10 ms more at the start for the smallest program: `p_if` fifty times under
`--jit`, 3.95 s to 4.47 s, 553 MB to 592 MB) and what many containers would make of it
(what one emulator takes before it runs anything is multiplied by the processes; as it
stands forty do not fit this host). The size is the machine's; what the Docker backend's
tables are to be instead is in `docs/roadmap.md` under M11: tables that cost what is used,
the blocks in a table of their own, translated code kept for the next process.

At 2^20, raced beside 2^18 at the same time so that both had the same load (it was 8 to
11): **72.8 s of CPU against 96.6 s**, `make-rc=0` in both. A run alone an hour before,
with the host as busy, took 106.9 s of CPU for the same counts (1.22 million blocks, 2
flushes): a time taken alone on this host says little, and from here the old and the new
are raced together.

All suites pass at 2^20: `difftest64` 32, `prim64` 23, `systest64` 17 plain, with `--jit`
and with `--jit-check` (106 `ok`).

----
## E153: NetHack built in the guest, g64m and QEMU raced at the same time (2026-11-23)

E148: 1,987 s of CPU against QEMU's 973 s, twice behind. Since then the short load and
store (E150) and the decode cache of 2^20 entries (E152): the three files went from 97.7 s
to about 70 s of CPU (QEMU: 65 s). The whole build has more code alive at once than the
three files (E143: three blocks in five were still lost to the cache at 2^18 with two
ways), so the cache's size should count for more there, or for as much.

- **Hypothesis**: **the whole build takes between 1,300 and 1,500 s of CPU under `--jit`
  (E148's 1,987 s less the three files' 28%), with under 100 flushes (from 293) and under
  5 billion entries (from 8.2 billion); QEMU takes 950 to 1,050 s of CPU beside it; g64m is
  between 1.25 and 1.6 times behind.**
- **What changed since last time**: E150 and E152; and the two programs run at the same
  time, each on its own core, so that they see the same host (E152: a time taken alone
  says little here).
- **Next move for each result**:
  - As guessed → what is left by E149's profile at this size: the interpreter's share
    again, the leavings, the XMM registers in memory
  - Still over 1.7 times → the whole build is not the three files: `--jit-why` on the
    whole build (the blocks lost, the instructions outside the cache)
  - Under 1.25 times → said so; the same next
- **Cut-off**: one build under each, together; `make-rc` and the NetHack's version in both.

**Result: g64m builds NetHack in 1,389 s of CPU alone (E148: 1,987 s), 1.43 times QEMU's
973 s alone; raced at the same time the two took 1,537 s and 1,293 s, 1.19 times.** Both
builds end at the same step with a NetHack that says its version.

| NetHack built in the guest | E148 | E153, at the same time | E153, alone |
|---|---:|---:|---:|
| g64m `--jit`, CPU (user) | 1,987 s | 1,537 s | **1,389 s** |
| QEMU 11.1.3, CPU (user) | 973 s | 1,293 s | 973 s (E148's, this morning) |
| g64m / QEMU | 2.0 | 1.19 | **1.43** |
| In blocks | 96.0% | 97.1% | |
| Entries into blocks | 8.2 billion | 6.2 billion | |
| Blocks translated | 91.2 million | 21.8 million | |
| Blocks lost to the cache | 54.4 million | 8.2 million | |
| Code written in all | 39.4 GB | 6.4 GB | |
| Times the room filled | 293 | 47 | |

- **The hypothesis** held for g64m alone (1,300 to 1,500 s: 1,389) and for the distance
  (1.25 to 1.6: 1.43 alone), and for the flushes (under 100: 47); the entries are 6.2
  billion for "under 5 billion".
- **Racing the two at the same time did not make the same host for both.** QEMU took a
  third more CPU beside g64m than alone (1,293 s for 973 s), g64m a tenth more (1,537 s
  for 1,389 s); the load was 5 to 8, with other work on the host than these two. With
  four fast cores and four slow ones, which program is put on a slow core is the
  system's choice, and a program put there takes more CPU for the same work. The pair
  says 1.19 and the two alone say 1.43; the two alone were hours apart. The distance is
  somewhere in 1.2 to 1.45, and the measure cannot say closer on this host as it is used.
  To say closer: the same race when nothing else runs, or a count that the host does not
  move (host instructions retired, which `/usr/bin/time -l` gives on this system).
- **Against E135** (3,561 s, 3.9 times): 1,426 s by the wall clock alone.

**Next.** The measure first: `tools/build_race.py` to print the host instructions retired
beside the CPU time, so that a ratio does not depend on which core ran what. Then what
E149's profile has left at this size.

----
## E154: a measure the host does not move: instructions retired (2026-11-23)

E153: the same build took QEMU 973 s of CPU alone and 1,293 s beside g64m; g64m 1,389 s
and 1,537 s. E152: one race alone took 106.9 s of CPU for work that takes 69 s on a quiet
hour. The host has four fast cores and four slow ones and other work on it; CPU time
counts seconds on whichever core, and a second on a slow core does less.

- **Hypothesis**: **the host instructions a program retires for the three files
  (`/usr/bin/time -l` gives them on this system) differ by under 1% between a run alone
  and a run with two more of the same beside it, where the CPU time differs by 5% or
  more; so two builds of g64m, or g64m and QEMU, can be compared by it at any hour, and
  three such runs can go at once.**
- **What changed since last time**: `tools/build_race.py` runs the program under
  `/usr/bin/time -l` and prints instructions retired and cycles beside the seconds.
- **Next move for each result**:
  - Under 1% → comparisons by instructions from here, up to three runs at once; the
    seconds beside them for what they are worth
  - Over 1% → what moves it (the guest's own clock: `--rtc host`, interrupts by the
    host's time) looked for; the count with the guest's clock by instructions
  - `time -l` gives no count for QEMU (its threads) → the count read another way
- **Cut-off**: the short race once alone and once three at once; QEMU once.

**Result: the count of host instructions holds still: 668.5 billion alone, 666.7 billion
in each of three runs at once (0.3% apart, and the three the same to five digits), where
the CPU time went from 66.8 s to 88.4 s.**

| Three of NetHack's files | CPU seconds | Host instructions retired | Cycles |
|---|---:|---:|---:|
| g64m `--jit`, alone | 66.8 | 668.5 billion | 210.6 billion |
| g64m `--jit`, three at once (each) | 88.3 to 88.5 | 666.7 billion | 263.7 to 264.6 billion |
| QEMU 11.1.3, alone | 58.5 | 497.7 billion | 184.9 billion |

- **The hypothesis** held: under 1% for the instructions (0.3%), far over 5% for the CPU
  time (32%). The cycles move as the seconds do.
- **g64m against QEMU on the three files, by each measure**: 1.34 times the host
  instructions, 1.14 times the cycles, 1.14 times the CPU seconds (alone, the same
  quarter of an hour). g64m retires more instructions for the same work (28 for a guest
  instruction, QEMU 21) and gets through them faster (3.2 a cycle against 2.7): its
  generated code is longer and simpler. So the instructions say whether g64m got
  better from one build to the next, at any hour and three at a time; they do not say how
  far it is from QEMU, which the cycles or seconds of two runs alone on a quiet host say.
- `tools/build_race.py` prints both from here; QEMU's run ends by the guest's power-off,
  so that `/usr/bin/time` can say what it took.

**Next.** What E149's profile has left: the interpreter's share at this size, the
leavings, the XMM registers in memory; each change measured by host instructions on the
three files (three variants at once), and by seconds alone before it is called a gain
on QEMU.

----
## E155: a block for what lies behind the place a block was left (2026-11-23)

At 2^20 entries (E152) the sampler has 66% of g64m's time in generated code on the three
files, 10% in `exec64` (finding what to run), about 9% in the interpreter proper, 3.5% in
page walks, 2.7% clearing the TLB, 2% translating. `--jit-why` on what the interpreter
runs (about 450 million instructions): a block's first instruction, the block left at
once, 113 million; an instruction inside a block, 90 million; not in the decode cache,
124 million; refused, 93 million; cold, 27 million.

A block is left in its middle when a load or store finds no entry in the TLB (after each
write of CR3 every page is met so once), and what follows the place is interpreted to the
next jump: E137 keeps an instruction inside a block from counting arrivals (a block
refused for the time slice would be made again from every place, E137's first form), so
no block is ever made there.

- **Hypothesis**: **with the instruction behind the one a block was left at (not for
  time) counted as a jump's landing is, so that after eight leavings at one place a block
  is made for the rest of the run, the instructions interpreted inside a block fall from
  90 million to under 30 million, the host instructions for the three files by 2% or more
  (668 billion to under 655 billion), with fewer than a fifth more blocks.**
- **What changed since last time**: the profile at 2^20. `jit_enter` says when a block
  came back before its end with time left; the second instruction interpreted after that
  is taken as landed on. `--jit-off` bit 38 turns it off, so that the two are raced from
  one build at the same time.
- **Next move for each result**:
  - 2% or more → the same for a block left before its first instruction ran (113
    million), if that count did not fall with it; then the TLB's clearing (2.7%)
  - Under 1% → the leavings are spread over too many places for eight at one: the count
    of places against leavings
  - More than a fifth more blocks → E137's trouble again: the places counted only for
    the ways out that are a memory's
- **Cut-off**: the two raced at once by host instructions; the gate.

**Result: 2.9% fewer host instructions for the three files (674.1 to 654.3 billion, the
two raced at once from one build), 4.0% fewer cycles; the instructions interpreted inside
a block fell from 90 million to 18 million, with 3% more blocks.**

| Three of NetHack's files | Off (`--jit-off` bit 38) | On |
|---|---:|---:|
| Host instructions retired | 674.1 billion | **654.3 billion** |
| Cycles | 234.0 billion | 224.6 billion |
| In blocks | 23.129 of 23.894 billion | 23.206 billion |
| Blocks translated | 1.216 million | 1.252 million |

- **The hypothesis** held: under 30 million inside a block (18), 2% or more (2.9%), under
  a fifth more blocks (3%).
- **What changed**: a way out that leaves the instruction it stands at to the
  interpreter (a load or store with no entry in the TLB, the SSE unit taken away, a
  division's edge) sets a word in what the block is given (`jx[24]`); `jit_enter` then
  takes the instruction behind that one as landed on (`jit_resume`), and not the one
  left, as it did: a block made at an instruction that leaves would leave at once, and
  113 million of a block's first instructions were interpreted so.
- **The switches** (`--jit-off`): only the low 32 bits are kinds now. The bits above,
  which are the translator's parts (38 this, 43 to 63 the others), were also read as the
  kinds of the conditional jumps and moves whose numbers they are, so that turning a
  part off turned a jump off with it; the first race of this change had the "off" side
  slower for that reason and was thrown away.

All suites pass (`tools/gate.sh`: 106 `ok`, `make-rc=0`, 416 s).

**Next.** By the profile at 2^20: the TLB emptied by clearing 196 KB at each write of CR3
(2.7% of the time, and the walks behind it 3.5%); the shifts' record settled on the way
into a block (19 million leavings); LEAVE and the string instructions.

----
## E156: the CPU the guest sees is not open to Meltdown or MDS, as QEMU's is not (2026-11-23)

The profile at 2^20 has 2.7% of g64m's time in clearing the TLB and 3.5% in walks. Looking
for how often the TLB is emptied, the guest's own log gave the reason before any count:
under g64m the kernel says `Kernel/User page tables isolation: enabled` and `MDS:
Vulnerable: Clear CPU buffers attempted`; under QEMU it says neither. g64m's CPUID is an
Intel Ivy Bridge's (family 6, model 3Ah), which the kernel's tables hold open to Meltdown
and MDS; QEMU's default CPU is an AMD one, which they do not. So g64m's guest changes CR3
on the way into the kernel and on the way out, for every system call and interrupt (each
a write of CR3 and an emptied TLB, with no PCID to keep anything), and runs VERW on each
way out; QEMU's guest does neither. The two programs have not been running the same work.

An emulator has no speculation to leak through. A CPU says so with
IA32_ARCH_CAPABILITIES (MSR 10Ah, announced by CPUID leaf 7's EDX bit 29): RDCL_NO for
Meltdown, MDS_NO, SSB_NO and the rest.

- **Hypothesis**: **with CPUID leaf 7 announcing ARCH_CAPABILITIES and the MSR saying the
  CPU is open to none of them, the kernel leaves page table isolation and the clearing of
  buffers off (its log says so), the TLB is emptied a tenth as often or less on the three
  files, and the host instructions fall by 8% or more (654 billion to under 602 billion).**
- **What changed since last time**: CPUID's highest leaf is 7; leaves 2 to 6 are zero;
  leaf 7 has EDX bit 29; MSR 10Ah reads the bits. The stats count the TLB's emptyings.
  `--cpu-open` gives the CPU as it was, so that the two are raced from one build.
- **Next move for each result**:
  - 8% or more → the whole build against QEMU, both alone; then the TLB's clearing for
    what emptyings are left
  - The kernel still isolates → what else its tables want (the model, the microcode's
    revision), read from its source's conditions
  - A system test prints differently (one that prints CPUID) → the expected text from
    hal's KVM is a real Ivy Bridge's: the test given `--cpu-open`, or its leaf not printed
- **Cut-off**: the two raced at once by host instructions; the kernel's log; the gate.

**Result: 30% fewer host instructions for the three files (647.7 to 456.0 billion), the
TLB emptied 23 thousand times for 1.5 million; and g64m is past QEMU on them: 50.5 s of
CPU against 61.4 s, raced at the same time.**

| Three of NetHack's files | The CPU as it was (`--cpu-open`) | The CPU now | QEMU 11.1.3 |
|---|---:|---:|---:|
| Host instructions retired | 647.7 billion | **456.0 billion** | 499.2 billion |
| Cycles | 221.6 billion | 153.3 billion | 192.2 billion |
| CPU seconds (the pair raced at once) | 71.5 | 49.7 | |
| CPU seconds (g64m and QEMU raced at once) | | **50.5** | 61.4 |
| The TLB emptied | 1,519,120 times | 23,421 times | |
| Entries into blocks | 301 million | 162 million | |
| Blocks translated | 1.25 million | 0.82 million | |

- **The hypothesis** held and was too small: 8% guessed, 30% found; the TLB emptied a
  sixty-fifth as often (a tenth guessed).
- **The kernel's log**: with the CPU as it was, `Kernel/User page tables isolation:
  enabled`, `MDS: Vulnerable: Clear CPU buffers attempted, no microcode`, `Speculative
  Store Bypass: Vulnerable`; now none of the three lines, and `Spectre V2 : Mitigation:
  Retpolines` as under QEMU.
- **What it was costing**: 1.5 million writes of CR3 in the three files, each one clearing
  196 KB of tags and leaving every page to be walked for again and every block that
  touched one to be left; and VERW, which no block has, on every way out of the kernel.
  That is the 2.7% of clearing and the 3.5% of walks, and most of what E149 to E155 were
  cutting at from the other side (the leavings to "another page, not in the TLB", the
  instructions left to the interpreter).
- **Every race against QEMU until now was of two different works.** E135's 3.9 times,
  E148's 2.0, E153's 1.2 to 1.45 were g64m with a guest that guards against Meltdown and
  MDS, against QEMU with a guest that does not. The changes between them were real (they
  are measured build against build, on the same guest); the distances to QEMU were not
  of like with like.
- **What changed**: CPUID's highest basic leaf is 7 and leaf 7's EDX has bit 29; MSR 10Ah
  reads 0D100171h (RDCL_NO, SSB_NO, MDS_NO, PSCHANGE_MC_NO, TAA_NO, BHI_NO, PBRSB_NO,
  GDS_NO, RFDS_NO). `--cpu-open` gives the CPU as it was. `--jit-stats` says how often the
  TLB was emptied.

All suites pass (`tools/gate.sh`: 106 `ok`, `make-rc=0`, 435 s).

**Next.** The whole build, g64m and QEMU, both ways (at the same time, and each alone).

----
## E157: NetHack built in the guest: g64m and QEMU on the same work (2026-11-23)

E156 found that every race until now had g64m's guest guarding against Meltdown and MDS
and QEMU's not; with the CPU saying what it is not open to, g64m takes 50.5 s of CPU for
three of NetHack's files to QEMU's 61.4 s. The whole build has more code alive at once and
more processes than the three files (E143, E153).

- **Hypothesis**: **the whole build takes g64m between 880 and 1,000 s of CPU alone
  (E153's 1,389 s less the three files' 30%), and QEMU 973 s as before: g64m is level
  with QEMU or up to a tenth ahead, by CPU seconds and by cycles; by host instructions it
  retires about as many.**
- **What changed since last time**: E155 and E156. `tools/build_race.py` gives host
  instructions and cycles for both. The two are raced at the same time, and then each
  alone, since E153 found the two ways apart.
- **Next move for each result**:
  - Level or ahead → the first of the owner's milestones is the build's; the primitives
    that are behind (rotations, packed SSE, x87) and the boot checked again on this CPU
  - Behind by more than a tenth → the whole build's `--jit-why` (the blocks lost at
    2^20, the leavings)
  - The build fails → E147's way
- **Cut-off**: one build under each at the same time, one each alone; `make-rc` and the
  NetHack's version in all four.

**Result: g64m builds NetHack in 812 s of CPU alone to QEMU's 1,074 s, and in 877 s to
1,142 s raced at the same time: a quarter ahead, both ways.** All four builds end at the
same step (`doc/Guidebook`) with a NetHack that says its version. Load 3 to 4.

| NetHack built in the guest | g64m `--jit` | QEMU 11.1.3 | g64m / QEMU |
|---|---:|---:|---:|
| At the same time: CPU seconds (user) | 876.6 | 1,142.3 | 0.77 |
| At the same time: cycles | 2,702 billion | 3,574 billion | 0.76 |
| At the same time: host instructions | 8,256 billion | 8,700 billion | 0.95 |
| Alone: CPU seconds (user) | **811.9** | **1,074.3** | **0.76** |
| Alone: wall clock | 825.8 s | 1,102.3 s | 0.75 |
| Alone: cycles | 2,547 billion | 3,391 billion | 0.75 |
| Alone: host instructions | 8,006 billion | 8,685 billion | 0.92 |

g64m alone: 470.7 billion guest instructions, 97.9% in blocks, 2.8 billion entries into
blocks, 15.1 million blocks translated (5.0 million lost to the cache), 4.8 GB of code
written, the room filled 35 times, the TLB emptied 31,165 times.

- **The hypothesis** was too careful: 812 s for "880 to 1,000"; a quarter ahead for
  "level, or up to a tenth ahead".
- **The two ways agree this time** (0.77 and 0.76 by CPU seconds), where E153's did not:
  the host had less on it (load 3 to 4, for 5 to 8).
- **By host instructions the two are near each other** (0.92 to 0.95): g64m gets through
  its instructions faster, 3.1 a cycle to QEMU's 2.6.
- **Against the first race** (E135, two days before: 3,561 s to QEMU's 914 s by the wall
  clock, with g64m's guest guarding against Meltdown and MDS): 826 s to 1,102 s.

**The owner's first milestone** (2026-11-22: past QEMU on every measured workload, before
the Docker backend) has three workloads. The build in the guest: past, by a quarter. The
boot: 2.42 s to 2.53 s in E134, to be taken again on this CPU. The primitives: 18 of 23
at QEMU's speed or past it in E131, `p_bitfield` since at 0.73; `p_simd`, `p_rotate`,
`p_sha`, `p_ldbl` and `p_pixel` behind.

**Next.** The boot and the 23 primitives against QEMU again, as they are now; then the
ones behind, in the order of their distance.
