# A JIT for the 64-bit CPU: the design

Written before any of it is built (E116 in [experiments.md](experiments.md)). The 32-bit
machine has a JIT ([jit.md](jit.md), `src/jit.goose`); this is that design carried over to
the 64-bit CPU (`src/cpu64.goose`), with what is the same, what is new, and the order of
work. It is kept up to date as the tasks at the end are done, as jit.md is.

## Why

| | Guest instructions a second | Host instructions for each |
|---|---:|---:|
| The 64-bit CPU, interpreted (after E114) | 62 million | 284 |
| The 32-bit CPU, interpreted | | 88 |
| The 32-bit CPU with its JIT (E073) | 341 million running X | 22 |

NetHack is built by GCC in 71 seconds on the real machine (an Ivy Bridge) and in more than
half an hour by the guest's GCC on g86m. Everything left in the interpreter's plan
([primitives64.md](primitives64.md)) is a factor of two at best.

## What the guest's code looks like to a translator (the boot, 1,524 million instructions)

Counted with the kinds the short front has now (E110: ALU with ModRM, MOV, the group
80h/81h/83h, TEST, LEA, MOVZX, PUSH, POP, CALL, RET, Jcc, JMP):

| | Share of the instructions | Runs | Mean length |
|---|---:|---:|---:|
| In a run of two or more of those kinds that ends at a jump (the jump included) | 53.3% | 220 million | 3.7 |
| In a run of two or more that ends at an instruction of no kind | 25.4% | 92 million | 4.2 |
| Of a kind, but alone between two instructions of no kind or two jumps | 5.9% | | |
| Of no kind | 13.7% | | |

So a translator that knew only the front's kinds would take 79% of the instructions, in
blocks under four instructions long: too short. What cuts the runs, by first byte (share
of all instructions): shifts and rotations `D3` 3.0%, `C1` 2.2%, `D1` 0.6%; the group
`F6`/`F7` (TEST with a constant, NOT, NEG, MUL, DIV) 2.5%; NOP in its two forms 1.8%;
MOVSXD 0.7%; MOV of a constant to a register (`B8` to `BF`) 0.8% and to an operand
(`C6`, `C7`) 0.5%; ENDBR64 0.5%; the group `FF` 0.2%; the forms with a constant and the A
register 0.3%; CMOV 0.1%. With those the kinds cover 97%.

The boot is the kernel unpacking itself and starting (0.2% of it at privilege level 3). A
user program's count is to be added here when there is one (NetHack built in the guest).

## What is the same as the 32-bit JIT

- **A block** is instructions that follow one another in one physical page, to a jump
  (included) or to an instruction the translator does not know (excluded), found through
  the decode cache: the entry of its first instruction gets the kind `K_BLOCK` and keeps
  its own kind beside it. The translator decodes nothing: it reads the entries (`Ins`,
  E109), which hold the prefixes, the operand size, and the ModRM's base, index, scale
  and displacement already.
- **Entering** from the short front, by one more arm of its jump on the kind. Nothing
  else of the JIT is in the interpreter's path.
- **Generated code never faults and never calls back.** Anything it cannot do (a TLB
  miss, a store into a page that holds code, a fault to come) leaves by a way out placed
  after the block, which gives back the address of that instruction and how many were
  executed before it; the interpreter runs that instruction.
- **Time.** A block takes its length off the time left before it begins. The run loop's
  test after every instruction (E106) needs nothing inside a block: what it asks about
  is set only by instructions that are not translated (STI, SYSCALL, HLT, a port) or at
  a time the run loop knows.
- **The flags as a record**: the last flag-setting instruction's operands and result in
  three host registers and its kind in a fourth; a conditional jump redoes the
  comparison with the host's flags; RFLAGS itself is made only where it is needed.
  Flags that nothing can see are not made.
- **Links** between blocks inside a page, a far way to a block in another page (looked up
  at every arrival, nothing remembered), translation at the eighth arrival, everything
  dropped when the room for code is full.
- **When a block dies**: a store into a page that holds decode-cache entries already
  goes the long way (`mem_wr_marked`, E107) and drops them; a generation number for the
  page, moved on there, makes its blocks stale.
- **The C**: `src/jit.c` (the mapping, the copy, the call) is used as it is.
- **Finding a wrong translation** by `--jit-off` with a bit for each group of kinds, and
  the count of instructions run in blocks printed, so that a test that runs none is seen.

## What is new

- **Sixteen registers, in host registers for the whole of a block.** arm64 has 28 that
  generated code may use (x0 to x17 and x19 to x28; it calls nothing, so none is lost to
  a call). Sixteen for the guest's; the memory array, the TLB, the time left, what a
  virtual address in the page is above a physical one; three for the flags' record and
  one for its kind; four scratch. That is 28: there is no room to spare, and the first
  thing to give way, if one more is needed, is the least used guest registers going to
  memory. The way in loads sixteen and the way out stores sixteen (eight instructions
  each with pairs).
- **Operands of 64, 32, 16 and 8 bits.** A 32-bit result clears the upper half, which
  is what a host instruction on a `w` register does. 8 and 16 bits are put into the
  register with a bit-field insert. The flags' record keeps the width in its kind.
- **Addresses relative to RIP, and the return address a CALL pushes.** A block is found
  by its physical address, and one page of a shared library is at different virtual
  addresses in different programs, so RIP cannot be a constant in generated code: it is
  the page's virtual base, held in a register, plus a constant. One instruction more
  where RIP is used.
- **Memory through the 64-bit TLB**: six tables (read, write and fetch, each for
  privilege level 3 and below it), a tag that is the whole page number, so one compare
  says both that the page is there and that the address is canonical. An access that
  runs over a page's end leaves by the way out, as do FS's and GS's bases at first.
- **Two kinds of run.** A program run without a kernel (`build/x64 program`) has no
  paging: its memory operand is a bounds test and an index. The translator makes one or
  the other when it translates.
- **No segments' limits**, which the 32-bit translator tests at every access and every
  jump.
- **A page that is both stored into and run** is given up by the decode cache after 32
  drops (E107), so it never gets blocks: the 32-bit JIT's task 8 does not arise.

## What is not known yet

- How long blocks are once the cutting instructions are kinds (the 32-bit boot's mean
  was not recorded either; its blocks are at most 60 instructions).
- Whether 28 registers are enough in practice, or which guest registers go to memory.
- What a user program's instructions look like: the count above is the kernel's.
- The cost in the interpreter of carrying the hook (the 32-bit one's was 0.1% to 1.1%).

## Tasks

Each becomes a card in the ledger when it is started. Measured on the primitives
(`tools/prim64_table.py`) and the boot; held to the real CPU by the suites there are
(`tools/difftest64.sh`, `tools/systest64.sh`, `tools/prim64.sh`), each run with and
without `--jit`.

| # | Task | Measured on |
|---|---|---|
| 1 | The kinds that cut the runs: shifts and rotations, `F6`/`F7`, NOP and ENDBR64, MOVSXD, MOV of a constant, the constant-and-A forms, CMOV and SETcc, the indirect CALL and JMP. In the short front first, so that each is tested as interpreted before it is translated | the count above, again |
| 2 | An emitter for arm64 with 64-bit operands (`src/jit64.goose`), the way in and out, and a block of instructions without memory operands, entered from the front; `--jit` on `build/x64` | `p_loop`, `p_if`, `p_shift` |
| 3 | The flags' record for four widths, and the jump that reads it | `p_ternary`, `p_switch`, the trace tests with `--jit` |
| 4 | Memory operands for a program without a kernel, with the way out | `p_pointer`, `p_index`, `p_bytes`, all the primitives |
| 5 | Memory operands through the TLB, and the stack (PUSH, POP, CALL, RET) | the system tests, the boot |
| 6 | Links inside a page and the far way | the boot, NetHack |
| 7 | What is left by count: the string instructions, MUL and DIV, the rest | the boot, NetHack built in the guest |
| 8 | The scalar SSE instructions | `p_dbl_arith`, `p_float` |
