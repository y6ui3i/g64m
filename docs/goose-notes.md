# Things Goose did that cost time

Goose is pinned to v2026.4. This file records only the language and compiler behaviour that actually
cost time.

## 1. A call that returns a narrower type, used as the left operand with a wider type, loses its width (compiler bug)

When a call to a function that returns a narrower integer is the **left** operand of a mixed-width
binary operation, the operation is carried out at the narrower width at `-O1` and `-O2` (the default).
It is correct when the call is the right operand, when the value is held in a variable, and at `-O0`.
Addition is affected as well as multiplication. The generated C has `gs_mul_u32` at `-O0` and
`gs_mul_u16` at `-O2`, so inlining drops the implicit widening.

Reported upstream: [aardappel/goose#313](https://github.com/aardappel/goose/issues/313)
(2026-11-12; reproduced on v2026.4 and on main at d5ae5bb).
The text that was sent is in [upstream-goose-issue-313.md](upstream-goose-issue-313.md).

```goose
import std;
fn narrow() -> u16 { return 0xFFFF; }
fn main() {
    let wide: u32 = 0xFFFF;
    let a: u16 = 0xFFFF;
    print(narrow() * wide, " ", a * wide);   // expected: 4294836225 twice
}
```

| How it is run | Output |
|---|---|
| `goose run` / `goose build` / `goose build --debug` | `1 4294836225` |
| `goose run -O0` | `4294836225 4294836225` |

How it was found: the high word of `MUL DI` (FFFFh × FFFFh) came out as 0, and the trace diff against
rustx86 showed it.

Workaround: before mixing widths, bind the narrow value to a typed local (`let a: u32 = r16(AX);`).
The multiply and divide code in `src/exec.goose` is written this way. Once the bug is fixed, the
workaround can go when the pinned Goose version is raised.

## 2. `%` floors; it does not truncate

Signed `%` returns a remainder with the sign of the divisor (`-32767 % 255` is `128`), while `/`
truncates toward zero. The remainder of x86 IDIV has the sign of the dividend, so it is computed as
`n - q * d`. The standard library's `rem` also returns the sign of the dividend.

## 3. Long-distance return makes CPU faults simple, with two conditions

A fault (a page fault, a protection fault) has to abandon the instruction from deep inside a memory
access. Goose's `return E from f` does exactly that: `raise` in `src/state.goose` ends with
`return false from exec_one`, and every frame between it and `exec_one` returns at once. No error
value is threaded through the callers.

The compiler checks that each call of a function that does this lies inside a call of `exec_one`.
Two things follow, and both produced errors on the way:

- **An unused function that can fault is an error.** A function nobody calls is not inside a call
  of `exec_one`, so `push16`, `pop16` and a `raise_ud` helper that had lost their last callers were
  rejected. Delete such helpers instead of keeping them around
- **Everything that can fault must run under the one function.** Delivering an interrupt pushes on
  the stack and so can fault; it could not stay in the run loop. This is the check doing its job

Related: files may import each other in a cycle, but globals are initialized imported file first.
`var saved: Cpu = cpu;` in the file that the file declaring `cpu` imports was rejected ("may be used
before it is assigned"). The global went into the file that declares `cpu`.

## 4. What generated code costs: things that were not obvious

They were found by counting host instructions for one guest instruction (`/usr/bin/time -l`
for the total, a debugger stepping one instruction for the detail). See E010 and E015 in
[experiments.md](experiments.md).

- **An integer `match` is a chain of comparisons.** There is no `switch` in the generated C. The C
  compiler rebuilds a jump table from the chain when every arm is a plain value; a range arm
  (`0x40..0x48`) stops it. Two ways round it: match on a few bits first so that level has only
  plain values, then match within; or write every value out (`0x40, 0x41, ..., 0x47 =>`), which
  gives one table. On a small interpreter the second took the gap to the same code in Rust from
  37% to 7%, and most of that gap was mispredicted branches, not extra instructions (E019). In
  g86m itself the first is what is used; the second was tried there and was slightly worse
- **Globals are laid out in the order their files are first imported**, in one block, and code
  reaches each by its offset. A large array early in that order pushes everything after it far
  away, and far offsets cost extra instructions on every access. Names are visible program-wide
  without an import, so a file of large arrays can be imported once, last, by the root file
  (`src/big.goose`)
- **Mark the small functions of a hot path `inline fn`.** The helpers of g86m's instruction path
  were all calls in the generated code: Goose had not inlined them, and the C compiler stops
  inlining into a function once it is large, which an interpreter's main function is. Each call saves and restores registers, and each call to something that can fault
  is followed by a test of the fault flag. Marking the helpers of the instruction path `inline fn`
  cut a quarter of the host instructions (E015). It costs build time: inlining one large function
  that is called from many places tripled it
- **Index with `i64`, and test the range where the indexes are.** Reading eight bytes as
  `ram[p]`, `ram[p + 1]`, ... with a `u32` `p` stayed eight loads: in 32-bit wrapping arithmetic
  `p + 1` does not provably follow `p`, so the C compiler will not merge them. With an `i64`
  index it is one load. And a range test passed in from the caller as a boolean does not remove
  the bounds checks; `if p < SIZE - 8 { ... }` around the indexing does. `goose build
  --bce-lines` says which checks are left (E017)
- **Adding a one-byte global can change the speed of code that never touches it.** Globals are
  packed, so a `bool` moves every global declared after it, in that file and in the files
  imported later, by one byte. In g86m one such `bool` made 16-bit code take a fifth more host
  cycles and 32-bit code 4% fewer host instructions, both through globals in other files.
  Declaring it as an `i64` left the rest where it was (E021). When a change slows something it
  does not touch, try padding before believing anything else
- **Globals and struct fields are packed, with no alignment.** A 32-bit field can sit at an odd
  address. On arm64 that costs one extra instruction per access. It was 1.5% when g86m was slow
  (E015) and 3.7% of the host instructions and 3.4% of the cycles once it was fast (E050): the
  extra instruction does not shrink with the rest. Ordering declarations widest first does not
  last, because every global added later moves the ones behind it; pad with a `u8` array in
  front of what matters and check the result. The generated C (under `GOOSE_HOME`) has the
  globals as one struct, so the C compiler's `offsetof` says where each one is
  (`tools/layout.sh`). One thing the layout shows that the source does not: a growable array
  (`u8[>..]`) is aligned to 8 inside the packed struct, so alignment starts again behind each
  one
- **`if c { x += n; }` becomes a conditional select, and a select is data.** Where `x` is what
  the next iteration of a loop starts from (in g86m, the address of the next guest instruction
  after a conditional jump), a select makes the next iteration wait for `c`, which a branch
  would have predicted. A store to a global on the taken path keeps it a branch. In g86m that
  store was there for another reason, was removed as redundant, and the Linux boot took 14%
  more cycles with 4% fewer instructions (E049). When a change that removes work makes the
  program slower by more than a few percent, look for a branch that turned into a select
- **A global that a loop both stores and loads each time round is a chain through memory.** The
  compiler cannot keep it in a register across a call that might change it, so each iteration
  waits for the store before it to be forwarded to its load. For g86m's instruction pointer that
  was 15 to 20 of the 27 host cycles a guest instruction cost; carrying it in a local, and only
  storing the global, took them off with the host instruction count unchanged (E026). Counting
  instructions does not show this; counting cycles for bodies of different lengths does
- **Indexing an array of structs multiplies by the struct's size**, and a load from it waits for
  that. For a 40-byte entry that is a multiply on the way to every load. What a loop needs in
  order to find its next element is better kept in an array of plain numbers beside the
  structs, indexed by a shift (E028: 5 of 16 cycles per guest instruction)
- **`/` is checked for a zero divisor**, by a call, even when the divisor is the literal 8. Use a
  shift on hot paths. Mind the precedence when replacing: `a + w >> 3` is not `a + (w >> 3)`

## 5. Small things

- `args`, `write_stderr` and `exit` need `import os;`
- A variable that holds a string literal is a `const u8[:]`
- Serialization (`to_bytes` / `from_bytes`) works on arrays. A single struct goes in a one-element array
- `--debug` is about 10 times slower. Tests run on both debug and release builds; measurements use release

## 6. Telling what a change to hot code did

What a Goose program costs is decided by the C compiler two steps away from the source, so a
change is judged by measuring, and the measuring has its own traps. All of these were met on
g86m's Linux boot (about 1.65 billion guest instructions, 30 billion host cycles).

- **Two rulers, for two questions.** The host instruction count (`/usr/bin/time -l`) repeats
  to within 0.01% and says whether anything changed at all; the cycle count varies by 1 to 2%
  and is what the time follows. They part company in both directions: carrying the instruction
  pointer in a local added host instructions and took 10% off the cycles (E026); a cheaper
  validity test took 8% off the instructions and 1% off the cycles (E030). Keep by cycles,
  check by instructions, and compare builds in alternating pairs, not one after the other
- **A third count says nothing broke.** The guest instruction count of a fixed workload must
  not move by one. A change that made the boot 16% faster by delivering interrupts late was
  caught by nothing else
- **Under about 0.6%, a gain cannot be told from where the code landed.** A few lines that
  never run, added to `main`, move the run loop by 56 to 248 bytes in the binary, and the
  boot's cycles move by up to 0.6% between such builds of the same source. A pair of single
  builds cannot see below that; a few padded builds of each side can (E047)
- **A gain from splitting an executor is not the sum of its parts.** Giving `mov` between
  registers its own executor gained between 1.2 and 1.9%, depending on how it is measured. Undoing either half of that change kept three
  quarters of the gain: it came from what the C compiler made of the loop once two calls were
  out of its most frequent arms, and counting operand forms did not predict where it would
  come again (E046, E047)
- **A row of one instruction repeated is a bad benchmark for a `match` dispatch.** The same
  `mov eax, 5` cost 14.7 cycles sixteen in a row, 12.8 four in a row and 11.2 sixty-four in a
  row: what is being measured is the host's branch predictor at the dispatch jump (E032)

## 7. No function pointers: what an interpreter is left with, and what it costs

Goose has no function pointers, so nothing can hold "what to run". Three consequences for
g86m, in order of how much they turned out to matter:

- **No JIT.** Generated code could not be called. This is the one that cannot be worked round
- **A decode cache holds what was parsed, not a handler.** An entry carries a small `kind`
  and its operands, and the run loop is one `match` on the kind (E017, E018). The dispatch is one indirect jump, as a table of handlers would be
- **Chaining entries into blocks is not worth it.** The load from one entry to the next is
  2 of a NOP's 10 cycles; an arrangement that removes it can win a tenth of the boot at the
  very most, and the one tried cost 16% (E032)

How far that goes, on the Linux boot to a shell, both programs given the same kernel and
initramfs on the same day (E048, Apple M1):

| | Time | Host instructions per guest instruction |
|---|---:|---:|
| g86m | 9.46 s | 99 |
| rustx86, interpreter | 16.57 s | 171 |
| rustx86, with its arm64 JIT | 11.95 s | 117 |

This compares two programs and not two languages: g86m has had some thirty measured changes
aimed at this boot, and rustx86 was finished before any of them. The comparison of the
languages is the 250-line fragment of E002 and E019, where Goose is 35% behind Rust as first
written and 7% behind with the `match` of section 4 written out. What the table does show is
that the missing function pointers and the missing JIT are not what bounds an interpreter
written in Goose.

# Found in rustx86

Behaviour of rustx86 that turned up while comparing g86m's tests with it. g86m does not follow it in
these cases. The first two were found on its 8086 profile, the rest on its 32-bit profile.

- **IDIV of -32768 by -1 panics.** `attempt to divide with overflow` at `core/src/cpu/group.rs:79`.
  Reproduced with the 8-bit form (`AX=8000h`, divisor `FFh`). The specified behaviour is a divide
  error (#DE). `tests/asm/s_selfcheck.asm` checks what g86m does
- **SALC (D6) leaves AL unchanged.** The specified behaviour is `AL = CF ? FFh : 00h`. It is an
  undocumented instruction, so the practical effect is small
- **BT, BTS, BTR and BTC on memory do not wrap an immediate bit offset.** `bts dword [m], 40`
  should act on bit 8 of the dword (the offset is taken modulo the operand size); rustx86 acts on
  bit 0 of the byte at `m+5`. With a 16-bit register offset it also treats the offset as unsigned,
  where the manual has it signed
- **IRETD in real mode pops 16-bit values.** The operand-size prefix is ignored on that path, so
  three words are popped instead of three dwords
- **FLD ST(i), FXCH and FSTP ST(i) drop the low 11 bits of an 80-bit value.** A value loaded with
  `FLD m80` keeps its 64 mantissa bits only until it is copied to another register; the copy has
  the 53 of an f64. Storing the copy with `FSTP m80` shows it. Real hardware copies all 80 bits.
  Seen for `FLD ST(0)`; its code does the same for the other two
- **Expected, not run: printf rounds floats down.** musl's printf asks whether `2^64 + small`
  differs from `2^64`, which needs a 64-bit mantissa. With f64 registers it never differs, so
  `printf '%g' 0.1` gives `0.0999999`. g86m did this with f64 registers (E013) and stopped when
  its arithmetic moved to the 80-bit format (E014); rustx86 has f64 registers.
- **REP MOVSD and REP MOVSW with the destination less than one element above the source copy
  byte by byte.** Each element should be read whole, then written; a later read then sees part
  of an earlier write. For `11 22 33 44 55 66 77 88 99`, two dwords, destination one byte up,
  the result should be `11 11 22 33 44 44 66 77 88`; rustx86 gives the bytes a byte-wise copy
  gives (E020)
