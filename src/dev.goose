// Devices: the interrupt controllers (8259), the timer (8254), the keyboard controller (8042),
// the CRT controller's cursor registers, and the I/O port dispatch that reaches them.

import std;
import os;

// ---- Interrupt controllers (8259 pair) ----

struct Pic {
    base: u8,        // vector of this controller's IRQ 0
    imr: u8,         // masked lines
    irr: u8,         // requested
    isr: u8,         // in service
    init: u8,        // which ICW comes next: 0 none, 2..4
    read_isr: bool,  // OCW3 selected ISR for the next read of the command port
}

var pic: Pic[2] = [Pic { base: 0x08, imr: 0xF8, irr: 0, isr: 0, init: 0, read_isr: false },
                   Pic { base: 0x70, imr: 0xFF, irr: 0, isr: 0, init: 0, read_isr: false }];

// True while some unmasked request could be delivered. Recomputed whenever a controller changes,
// so the run loop tests one bool per instruction.
var irq_line = false;

// The lowest-numbered request that is unmasked and not blocked by one in service; -1 if none.
fn pic_candidate(k: i64) -> i64 {
    let ready = pic[k].irr & ~pic[k].imr;
    for n: u8 in 0..8 {
        let bit: u8 = 1 << n;
        if pic[k].isr & bit != 0 { return -1; }
        if ready & bit != 0 { return n; }
    }
    return -1;
}

fn pic_update() {
    // The slave hangs off the master's line 2.
    if pic_candidate(1) >= 0 { pic[0].irr |= 4; } else { pic[0].irr &= ~4; }
    irq_line = pic_candidate(0) >= 0;
}

fn raise_irq(n: u8) {
    if n < 8 { pic[0].irr |= 1 << n; } else { pic[1].irr |= 1 << (n - 8); }
    pic_update();
}

// Acknowledges the pending request and returns its vector.
fn pic_ack() -> u8 {
    let n = pic_candidate(0);
    if n < 0 { return pic[0].base + 7; }
    let bit: u8 = 1 << n;
    if n == 2 {
        let m = pic_candidate(1);
        if m >= 0 {
            let mbit: u8 = 1 << m;
            pic[1].irr &= ~mbit;
            pic[1].isr |= mbit;
            pic[0].isr |= bit;
            pic_update();
            return pic[1].base + (m as! u8);
        }
    }
    pic[0].irr &= ~bit;
    pic[0].isr |= bit;
    pic_update();
    return pic[0].base + (n as! u8);
}

fn pic_command(k: i64, v: u8) {
    if v & 0x10 != 0 {                       // ICW1: start initialization
        pic[k].init = 2;
        pic[k].imr = 0;
        pic[k].isr = 0;
        pic[k].irr = 0;
        pic[k].read_isr = false;
    } else if v & 0x08 != 0 {                // OCW3
        if v & 0x02 != 0 { pic[k].read_isr = v & 0x01 != 0; }
    } else {                                 // OCW2
        if v & 0x20 != 0 {
            if v & 0x40 != 0 {               // specific EOI
                pic[k].isr &= ~(1 << (v & 7));
            } else {                         // non-specific: clear the highest priority in service
                for n: u8 in 0..8 {
                    let bit: u8 = 1 << n;
                    if pic[k].isr & bit != 0 { pic[k].isr &= ~bit; break; }
                }
            }
        }
    }
    pic_update();
}

fn pic_data(k: i64, v: u8) {
    if pic[k].init == 2 { pic[k].base = v & 0xF8; pic[k].init = 3; }
    else if pic[k].init == 3 { pic[k].init = 4; }
    else if pic[k].init == 4 { pic[k].init = 0; }
    else { pic[k].imr = v; }
    pic_update();
}

// ---- Timer (8254) ----
//
// The virtual clock is the instruction count: the timer's 1,193,182 Hz input advances one tick
// every tick_insns instructions. Only channel 0 raises an interrupt.

var tick_insns = 4;          // 64 for the 32-bit machine, as rustx86 has it

struct Channel {
    reload: u32,     // 0 means 65536
    mode: u8,
    access: u8,      // 1 low byte, 2 high byte, 3 low then high
    write_hi: bool,
    read_hi: bool,
    latched: bool,
    latch: u16,
    pending: u16,    // low byte of a two-byte write
}

var pit: Channel[3] = [Channel { reload: 0, mode: 3, access: 3, write_hi: false, read_hi: false, latched: false, latch: 0, pending: 0 },
                       Channel { reload: 18, mode: 2, access: 1, write_hi: false, read_hi: false, latched: false, latch: 0, pending: 0 },
                       Channel { reload: 0, mode: 3, access: 3, write_hi: false, read_hi: false, latched: false, latch: 0, pending: 0 }];

// Padding: Goose packs globals, and what follows is to sit at a multiple of 8 (E050;
// tools/layout.sh shows where each global is, and tools/difftest.sh checks these).
var pad_timer: u8[3] = [0; 3];
var timer_on = true;         // channel 0 is counting
var timer_at = 262144;       // the virtual time at which channel 0 next reaches zero

// The run loop executes instructions without looking up until virtual time reaches a moment it
// worked out beforehand. Whatever changes when the next event is due sets this, and the loop
// looks up after the instruction that did it.
var replan = false;

fn pit_period() -> i64 {
    let n: i64 = if pit[0].reload == 0 { 65536 } else { pit[0].reload };
    return n * tick_insns;
}

// Channel 0 reached zero.
fn timer_fire() {
    raise_irq(0);
    timer_at = vtime + pit_period();
    if pit[0].mode != 2 && pit[0].mode != 3 { timer_on = false; }     // one-shot modes stop
}

// Channel 2 drives the speaker and is also what software times short intervals with: it loads a
// count, opens the gate at port 61h, and watches the channel's output there. Its count is worked
// out from the virtual time at which it was loaded.
var ch2_loaded_at = 0;

// Timer ticks since channel 2 was loaded.
fn ch2_elapsed() -> i64 { return (vtime - ch2_loaded_at) / tick_insns; }

// Channel 2's output pin: in mode 0 it goes high once the count has run out.
fn ch2_out() -> bool {
    let n: i64 = if pit[2].reload == 0 { 65536 } else { pit[2].reload };
    if pit[2].mode == 0 { return ch2_elapsed() >= n; }
    return ch2_elapsed() % n < n / 2;          // a square wave in the other modes
}

fn pit_count(k: i64) -> u16 {
    if k == 0 { return ((timer_at - vtime) / tick_insns) as! u16; }
    if k == 2 {
        let n: i64 = if pit[2].reload == 0 { 65536 } else { pit[2].reload };
        let gone = ch2_elapsed();
        if pit[2].mode == 0 { return (if gone >= n { 0 } else { n - gone }) as! u16; }
        return (n - gone % n) as! u16;
    }
    return pit[k].reload as! u16;
}

fn pit_control(v: u8) {
    let k: i64 = v >> 6;
    if k == 3 { return; }                    // read-back command: not modelled
    let access = v >> 4 & 3;
    if access == 0 {                         // latch the current count
        pit[k].latch = pit_count(k);
        pit[k].latched = true;
        pit[k].read_hi = false;
        return;
    }
    pit[k].access = access;
    pit[k].mode = v >> 1 & 7;
    if pit[k].mode > 5 { pit[k].mode -= 4; }
    pit[k].write_hi = false;
    pit[k].read_hi = false;
    // A control word alone stops the count until a new value is written.
    if k == 0 { timer_on = false; replan = true; }
}

fn pit_write(k: i64, v: u8) {
    if pit[k].access == 3 {
        if !pit[k].write_hi { pit[k].pending = v; pit[k].write_hi = true; return; }
        pit[k].write_hi = false;
        pit[k].reload = pit[k].pending | (v as u32) << 8;
    } else if pit[k].access == 2 {
        pit[k].reload = (v as u32) << 8;
    } else {
        pit[k].reload = v;
    }
    if k == 0 { timer_on = true; timer_at = vtime + pit_period(); replan = true; }
    if k == 2 { ch2_loaded_at = vtime; }
}

fn pit_read(k: i64) -> u8 {
    let v = if pit[k].latched { pit[k].latch } else { pit_count(k) };
    if pit[k].access == 3 {
        if !pit[k].read_hi { pit[k].read_hi = true; return v as! u8; }
        pit[k].read_hi = false;
        pit[k].latched = false;
        return (v >> 8) as! u8;
    }
    pit[k].latched = false;
    if pit[k].access == 2 { return (v >> 8) as! u8; }
    return v as! u8;
}

// ---- Keyboard controller (8042) ----

let KBD_QUEUE = 256;

var kbd_queue: u8[KBD_QUEUE] = [0; KBD_QUEUE];
var kbd_head = 0;
var kbd_tail = 0;
var kbd_out: u8 = 0;         // the output buffer the guest reads at port 60h
var kbd_full = false;
var kbd_command: u8 = 0;     // controller command waiting for its data byte, or 0
var kbd_config: u8 = 0x45;   // command byte: interrupt on, system flag, translation
var port_b: u8 = 0;          // port 61h (speaker gate and friends)
var refresh: u8 = 0;

// The controller's second port: a PS/2 mouse (E078). Its bytes wait in a queue of their own
// and reach the guest through the same output buffer, marked as the mouse's in the status
// register, with IRQ 12. After rustx86's mouse.rs: a plain three-button mouse that answers
// what a driver asks while it looks for something fancier, and, once told to, reports
// movement in packets of three bytes.
var aux_queue: u8[KBD_QUEUE] = [0; KBD_QUEUE];
var aux_head = 0;
var aux_tail = 0;
var kbd_out_aux = false;     // the byte in the output buffer is the mouse's
var mouse_on = false;        // reporting
var mouse_arg = false;       // the next byte to the mouse is a command's argument
var pad_mouse: u8[5] = [0; 5];

// Moves the next queued byte into the output buffer and raises its interrupt: the keyboard's
// first, IRQ 1; then the mouse's, IRQ 12.
fn kbd_pump() {
    if kbd_full { return; }
    if kbd_head != kbd_tail {
        kbd_out = kbd_queue[kbd_head];
        kbd_head = (kbd_head + 1) % KBD_QUEUE;
        kbd_full = true;
        kbd_out_aux = false;
        if kbd_config & 1 != 0 { raise_irq(1); }
    } else if aux_head != aux_tail {
        kbd_out = aux_queue[aux_head];
        aux_head = (aux_head + 1) % KBD_QUEUE;
        kbd_full = true;
        kbd_out_aux = true;
        if kbd_config & 2 != 0 { raise_irq(12); }
    }
}

fn aux_push(v: u8) {
    let next = (aux_tail + 1) % KBD_QUEUE;
    if next == aux_head { return; }
    aux_queue[aux_tail] = v;
    aux_tail = next;
    kbd_pump();
}

// A byte the guest sends to the mouse (controller command D4h, then the byte).
fn mouse_command(v: u8) {
    if mouse_arg { mouse_arg = false; aux_push(0xFA); return; }
    aux_push(0xFA);                              // every command is acknowledged
    match v {
        0xFF => { aux_push(0xAA); aux_push(0x00); mouse_on = false; },      // reset: passed, and it is a mouse
        0xF2 => { aux_push(0x00); },                                        // which kind: the plain one
        0xF4 => { mouse_on = true; },
        0xF5, 0xF6 => { mouse_on = false; },
        0xF3, 0xE8 => { mouse_arg = true; },                                // sample rate, resolution: an argument follows
        0xE9 => { aux_push(if mouse_on { 0x20 } else { 0 }); aux_push(2); aux_push(100); },
        0xEB => { aux_push(0x08); aux_push(0); aux_push(0); },
        _ => {},
    }
}

// The mouse moved by dx to the right and dy up, with its buttons as given (1 left, 2 right,
// 4 middle): one packet, if the guest has asked for reports and the queue has room for all
// three bytes.
fn mouse_move(dx0: i64, dy0: i64, buttons: u8) {
    if !mouse_on || (aux_tail - aux_head + KBD_QUEUE) % KBD_QUEUE > KBD_QUEUE - 4 { return; }
    let dx = if dx0 > 255 { 255 } else if dx0 < -255 { -255 } else { dx0 };
    let dy = if dy0 > 255 { 255 } else if dy0 < -255 { -255 } else { dy0 };
    var b: u8 = 0x08 | buttons & 7;
    if dx < 0 { b |= 0x10; }
    if dy < 0 { b |= 0x20; }
    aux_push(b);
    aux_push(dx as! u8);
    aux_push(dy as! u8);
}

fn kbd_push(v: u8) {
    let next = (kbd_tail + 1) % KBD_QUEUE;
    if next == kbd_head { return; }          // full: the byte is dropped
    kbd_queue[kbd_tail] = v;
    kbd_tail = next;
    kbd_pump();
}

fn kbd_queued() -> i64 { return (kbd_tail - kbd_head + KBD_QUEUE) % KBD_QUEUE; }

fn kbd_read_data() -> u8 {
    let v = kbd_out;
    kbd_full = false;
    kbd_pump();
    return v;
}

fn kbd_write_data(v: u8) {
    if kbd_command == 0x60 { kbd_config = v; kbd_command = 0; return; }
    if kbd_command == 0xD4 { kbd_command = 0; mouse_command(v); return; }
    // The byte comes back as if a device had sent it: the mouse (D3h), which is how a driver
    // finds out that the second port and its interrupt are there, or the keyboard (D2h).
    if kbd_command == 0xD3 { kbd_command = 0; aux_push(v); return; }
    if kbd_command == 0xD2 { kbd_command = 0; kbd_push(v); return; }
    if kbd_command != 0 { kbd_command = 0; return; }       // data for a command not modelled
    // A byte for the keyboard itself (LEDs, typematic, reset ...): acknowledge it.
    if v == 0xFF { kbd_push(0xFA); kbd_push(0xAA); return; }
    kbd_push(0xFA);
}

fn kbd_write_command(v: u8) {
    match v {
        0x20 => { kbd_push(kbd_config); },
        0x60, 0xD1, 0xD2, 0xD3, 0xD4 => { kbd_command = v; },
        0xA7 => { kbd_config |= 0x20; },             // the second port off,
        0xA8 => { kbd_config &= ~0x20; },            // and on
        0xA9 => { kbd_push(0x00); },                 // its test: passed
        0xAA => { kbd_push(0x55); },
        0xAB => { kbd_push(0x00); },
        0xD0 => { kbd_push(0x02); },
        _ => {},
    }
}

// ---- CRT controller ----

var crtc_index: u8 = 0;
var crtc: u8[32] = [0; 32];
var retrace: u8 = 0;

// ---- Diagnostic port and serial port (used by the test386 ROM) ----

var post_trail: u8[>..];     // every code written to the diagnostic port, in order

// COM1, a 16550 without its FIFOs. What the guest sends is kept in com_out and, when com_live is
// set, also written to our standard output as it arrives. What we want the guest to receive
// waits in a queue. The port interrupts on IRQ 4, for a received byte and for "ready to send".
let COM_QUEUE = 1024;

var com_out: u8[>..];
var com_line: u8[>..];       // output not yet written to standard output
var com_live = false;
var com_rx: u8[COM_QUEUE] = [0; COM_QUEUE];
var com_rx_head = 0;
var com_rx_tail = 0;
var com_ier: u8 = 0;         // interrupt enable register
var com_lcr: u8 = 0;         // line control register; bit 7 opens the divisor latch
var com_mcr: u8 = 0;         // modem control register; bit 4 is loopback
var com_scr: u8 = 0;         // scratch register
var com_dll: u8 = 1;         // baud rate divisor
var com_dlm: u8 = 0;
var com_thre = false;        // "ready to send" has not been reported to the guest yet

fn com_has_input() -> bool { return com_rx_head != com_rx_tail; }

fn com_update() {
    if (com_ier & 1 != 0 && com_has_input()) || (com_ier & 2 != 0 && com_thre) { raise_irq(4); }
}

// Queues a byte for the guest to receive.
fn com_receive(v: u8) {
    let next = (com_rx_tail + 1) % COM_QUEUE;
    if next == com_rx_head { return; }
    com_rx[com_rx_tail] = v;
    com_rx_tail = next;
    com_update();
}

fn com_flush() {
    if com_line.len > 0 { write_stdout(com_line); flush_stdout(); com_line.clear(); }
}

fn com_read(reg: u16) -> u8 {
    let dlab = com_lcr & 0x80 != 0;
    match reg {
        0 => {
            if dlab { return com_dll; }
            if !com_has_input() { return 0; }
            let v = com_rx[com_rx_head];
            com_rx_head = (com_rx_head + 1) % COM_QUEUE;
            return v;
        },
        1 => { return if dlab { com_dlm } else { com_ier }; },
        2 => {
            // Interrupt identification: the highest-priority pending cause, or 1 for none.
            if com_ier & 1 != 0 && com_has_input() { return 0x04; }
            if com_ier & 2 != 0 && com_thre { com_thre = false; return 0x02; }
            return 0x01;
        },
        3 => { return com_lcr; },
        4 => { return com_mcr; },
        5 => { return if com_has_input() { 0x61 } else { 0x60 }; },      // sender idle; data ready
        6 => {
            // Modem status. In loopback the four inputs are wired to the four outputs.
            if com_mcr & 0x10 != 0 { return (com_mcr & 2) << 3 | (com_mcr & 1) << 5 | (com_mcr & 0x0C) << 4; }
            return 0xB0;
        },
        _ => { return com_scr; },
    }
}

fn com_write(reg: u16, v: u8) {
    let dlab = com_lcr & 0x80 != 0;
    match reg {
        0 => {
            if dlab { com_dll = v; return; }
            com_out.push(v);
            if com_live {
                com_line.push(v);
                if v == '\n' || com_line.len >= 256 { com_flush(); }
            }
            com_thre = true;
            com_update();
        },
        1 => {
            if dlab { com_dlm = v; return; }
            // Enabling the "ready to send" interrupt while the sender is idle raises it at once.
            if v & 2 != 0 && com_ier & 2 == 0 { com_thre = true; }
            com_ier = v & 0x0F;
            com_update();
        },
        2 => {},                                 // FIFO control: no FIFOs
        3 => { com_lcr = v; },
        4 => { com_mcr = v; },
        7 => { com_scr = v; },
        _ => {},
    }
}

// ---- CMOS memory and the clock (MC146818, ports 70h and 71h) ----
//
// A register number is written to port 70h and the register read or written at 71h. The
// clock's registers are not stored: they are made, when read, from the time the clock was
// started at and the guest's own time since, which is the instruction count as for the
// timer. So the clock is as repeatable as everything else; the time it starts at is an
// input (a fixed one unless the command line or a terminal says otherwise; see main).
// There is no alarm, no periodic interrupt, and the update-in-progress bit is never set.

var cmos: u8[128] = [0; 128];
var cmos_index: u8 = 0;
var cmos_ready = false;
var pad_cmos: u8[6] = [0; 6];
var rtc_base: i64 = 1767225600;      // 2026-01-01 00:00:00 UTC, as rustx86 has it

// Seconds since 1970 on the guest's clock.
fn rtc_now() -> i64 { return rtc_base + vtime / (tick_insns * 1193182); }

// The clock's fields for a count of seconds since 1970: second, minute, hour, day of the
// week (1 is Sunday), day, month, year. (The days to a date by Howard Hinnant's
// civil_from_days.)
fn rtc_fields(s: i64) -> i64[7] {
    let days = s / 86400;
    let rem = s % 86400;
    let z = days + 719468;
    let era = z / 146097;
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = yoe + era * 400 + (if m <= 2 { 1 } else { 0 });
    return [rem % 60, rem % 3600 / 60, rem / 3600, (days + 4) % 7 + 1, d, m, y];
}

// And back: seconds since 1970 for a date and a time of day.
fn rtc_seconds(f: i64[7]) -> i64 {
    let m = f[5];
    let y = if m <= 2 { f[6] - 1 } else { f[6] };
    let era = y / 400;
    let yoe = y - era * 400;
    let doy = (153 * (if m > 2 { m - 3 } else { m + 9 }) + 2) / 5 + f[4] - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return (era * 146097 + doe - 719468) * 86400 + f[2] * 3600 + f[1] * 60 + f[0];
}

// Which field a register is: -1 for a register that is not the clock's, 7 for the century.
fn rtc_which(i: u8) -> i64 {
    match i {
        0x00 => { return 0; },
        0x02 => { return 1; },
        0x04 => { return 2; },
        0x06 => { return 3; },
        0x07 => { return 4; },
        0x08 => { return 5; },
        0x09 => { return 6; },
        0x32 => { return 7; },
        _ => { return -1; },
    }
}

fn cmos_setup() {
    cmos_ready = true;
    cmos[0x0A] = 0x26;               // status A: the divider; no update in progress
    cmos[0x0B] = 0x02;               // status B: 24 hours, BCD
    cmos[0x0D] = 0x80;               // status D: the battery is good
    cmos[0x10] = 0x40;               // one 1.44 MB floppy drive
    cmos[0x14] = 0x21;               // equipment
    cmos[0x15] = 0x80;               // 640 KB of base memory
    cmos[0x16] = 0x02;
}

// A clock register as the guest reads it: BCD unless status B says binary.
fn rtc_read(k: i64, bcd: bool) -> u8 {
    let f = rtc_fields(rtc_now());
    var v = if k == 7 { f[6] / 100 } else if k == 6 { f[6] % 100 } else { f[k] };
    if bcd { v = v / 10 * 16 + v % 10; }
    return v as! u8;
}

fn cmos_read() -> u8 {
    if !cmos_ready { cmos_setup(); }
    let k = rtc_which(cmos_index);
    if k >= 0 { return rtc_read(k, cmos[0x0B] & 4 == 0); }
    return cmos[cmos_index];
}

// The guest sets its clock by writing the fields one after another: each write moves the
// start time so that the field reads back as written and the others as they were.
fn cmos_write(v: u8) {
    if !cmos_ready { cmos_setup(); }
    let k = rtc_which(cmos_index);
    if k < 0 { cmos[cmos_index] = v; return; }
    var x: i64 = v;
    if cmos[0x0B] & 4 == 0 { x = x / 16 * 10 + x % 16; }
    let now = rtc_now();
    var f = rtc_fields(now);
    if k == 7 { f[6] = x * 100 + f[6] % 100; }
    else if k == 6 { f[6] = f[6] / 100 * 100 + x; }
    else if k == 3 { return; }       // the day of the week follows from the date
    else { f[k] = x; }
    if f[5] < 1 || f[5] > 12 || f[4] < 1 || f[4] > 31 || f[6] < 1970 || f[6] > 2399 { return; }
    rtc_base += rtc_seconds(f) - now;
}

// ---- IDE disk (ATA, the primary channel: ports 1F0h to 1F7h and 3F6h, IRQ 14) ----
//
// One disk, the master; the slave is absent and reads as zero. PIO only: the host reads and
// writes the data port, a block of sectors at a time, and the disk raises its interrupt
// when a block is ready to be read or has been taken. A command is carried out at once.
// The sectors are in a file on the host (disk.c), written in place. With no --disk there is
// no channel: the ports answer as ports nothing is at.

extern fn disk_open(path: const u8[:], scratch: i32) -> i64;
extern fn disk_read(lba: i64, buf: u8[:]) -> i32;
extern fn disk_write(lba: i64, buf: const u8[:]) -> i32;

let IDE_BUF = 8192;                  // sixteen sectors: the most a READ or WRITE MULTIPLE block is
var ide_sectors: i64 = 0;            // how many the disk has; 0 for no disk
var ide_buf: u8[IDE_BUF] = [0; IDE_BUF];
var ide_pos: i64 = 0;                // where in the buffer the host is
var ide_end: i64 = 0;                // and where the block ends
var ide_next: i64 = 0;               // the sector the next block begins at
var ide_left: i64 = 0;               // sectors still to come, the block in the buffer included for a write
var ide_blk: i64 = 1;                // sectors to a block, for the command at hand
var ide_mult: i64 = 1;               // and for the MULTIPLE commands, as SET MULTIPLE MODE left it
var ide_reads: i64 = 0;              // sectors read and written, for the report
var ide_writes: i64 = 0;
// Sector count and the three LBA registers each hold two bytes: the one written last and
// the one before, which the 48-bit commands take as the upper half.
var ide_cnt: u8[2] = [1, 0];
var ide_lba: u8[6] = [1, 0, 0, 0, 0, 0];
var ide_err: u8 = 1;
var ide_feat: u8 = 0;
var ide_drive: u8 = 0;
var ide_status: u8 = 0x50;           // ready, seek complete
var ide_ctl: u8 = 0;                 // 2: no interrupts; 4: reset; 80h: read the bytes before
var ide_mode: u8 = 0;                // 0 idle, 1 the host reads, 2 the host writes
var pad_ide: u8[1] = [0; 1];

// After a reset, and after EXECUTE DEVICE DIAGNOSTIC: the signature of an ATA device.
fn ide_reset() {
    ide_err = 1;
    ide_cnt = [1, 0];
    ide_lba = [1, 0, 0, 0, 0, 0];
    ide_drive = 0;
    ide_status = 0x50;
    ide_mode = 0;
    ide_mult = 1;
}

fn ide_irq() { if ide_ctl & 2 == 0 { raise_irq(14); } }

// The command is done; with err, refused or failed.
fn ide_done(err: u8) {
    ide_mode = 0;
    ide_err = err;
    ide_status = if err != 0 { 0x51 } else { 0x50 };
    ide_irq();
}

// The next block from the disk into the buffer, for the host to read.
fn ide_load() {
    let n = if ide_left < ide_blk { ide_left } else { ide_blk };
    if disk_read(ide_next, ide_buf[..n * 512]) != 0 { ide_done(0x40); return; }     // an uncorrectable error
    ide_reads += n;
    ide_next += n;
    ide_left -= n;
    ide_pos = 0;
    ide_end = n * 512;
    ide_mode = 1;
    ide_status = 0x58;               // data request
    ide_irq();
}

// A read or a write of `count` sectors from `lba` on, `blk` to a block.
fn ide_rw(write: bool, lba: i64, count: i64, blk: i64) {
    if lba + count > ide_sectors { ide_done(0x14); return; }        // no such sector
    ide_next = lba;
    ide_left = count;
    ide_blk = blk;
    if !write { ide_load(); return; }
    // The host writes the first block without being asked by an interrupt.
    ide_pos = 0;
    ide_end = (if count < blk { count } else { blk }) * 512;
    ide_mode = 2;
    ide_status = 0x58;
}

fn ide_word(i: i64, v: i64) {
    ide_buf[i * 2] = v as! u8;
    ide_buf[i * 2 + 1] = (v >> 8) as! u8;
}

// A string of the IDENTIFY data: two characters to a word, the first in the high byte.
fn ide_text(i: i64, words: i64, t: const u8[:]) {
    for k in words * 2 {
        let c: u8 = if k < t.len { t[k] } else { 32 };
        ide_buf[i * 2 + (k ^ 1)] = c;
    }
}

// IDENTIFY DEVICE: what the disk is.
fn ide_identify() {
    for i in 512 { ide_buf[i] = 0; }
    var cyl = ide_sectors / (16 * 63);
    if cyl > 16383 { cyl = 16383; }
    let chs = cyl * 16 * 63;
    let lba28 = if ide_sectors > 0x0FFFFFFF { 0x0FFFFFFF } else { ide_sectors };
    ide_word(0, 0x0040);             // a fixed disk
    ide_word(1, cyl);
    ide_word(3, 16);
    ide_word(6, 63);
    ide_text(10, 10, "G86M0001");
    ide_text(23, 4, "1");
    ide_text(27, 20, "g86m disk");
    ide_word(47, 0x8010);            // READ and WRITE MULTIPLE: up to 16 sectors
    ide_word(49, 0x0200);            // LBA; no DMA
    ide_word(50, 0x4000);
    ide_word(51, 0x0200);            // PIO mode 2
    ide_word(53, 0x0003);            // words 54 to 58 and 64 to 70 are valid
    ide_word(54, cyl);
    ide_word(55, 16);
    ide_word(56, 63);
    ide_word(57, chs);
    ide_word(58, chs >> 16);
    ide_word(59, 0x0100 | ide_mult);
    ide_word(60, lba28);
    ide_word(61, lba28 >> 16);
    ide_word(64, 0x0003);            // PIO modes 3 and 4
    ide_word(80, 0x007E);            // ATA-1 to ATA-6
    ide_word(82, 0x4000);            // NOP
    ide_word(83, 0x7400);            // 48-bit addresses, FLUSH CACHE and FLUSH CACHE EXT
    ide_word(84, 0x4000);
    ide_word(85, 0x4000);
    ide_word(86, 0x3400);
    ide_word(87, 0x4000);
    ide_word(100, ide_sectors);
    ide_word(101, ide_sectors >> 16);
    ide_word(102, ide_sectors >> 32);
    ide_pos = 0;
    ide_end = 512;
    ide_left = 0;
    ide_mode = 1;
    ide_status = 0x58;
    ide_irq();
}

fn ide_command(c: u8) {
    let lo: i64 = ide_lba[0];
    let mid: i64 = ide_lba[1];
    let hi: i64 = ide_lba[2];
    let head: i64 = ide_drive & 15;
    // 28 bits: an LBA, or (bit 6 of the drive register clear) cylinder, head and sector.
    var lba = head << 24 | hi << 16 | mid << 8 | lo;
    if ide_drive & 0x40 == 0 { lba = ((hi << 8 | mid) * 16 + head) * 63 + lo - 1; }
    let cnt: i64 = if ide_cnt[0] == 0 { 256 } else { ide_cnt[0] };
    // 48 bits: the bytes written before are the upper halves.
    let p0: i64 = ide_lba[3];
    let p1: i64 = ide_lba[4];
    let p2: i64 = ide_lba[5];
    let lba48 = p2 << 40 | p1 << 32 | p0 << 24 | hi << 16 | mid << 8 | lo;
    let c0: i64 = ide_cnt[0];
    let c1: i64 = ide_cnt[1];
    let cnt48 = if c0 == 0 && c1 == 0 { 65536 } else { c1 << 8 | c0 };
    match c {
        0xEC => { ide_identify(); },
        0x20, 0x21 => { ide_rw(false, lba, cnt, 1); },
        0xC4 => { ide_rw(false, lba, cnt, ide_mult); },
        0x24 => { ide_rw(false, lba48, cnt48, 1); },
        0x29 => { ide_rw(false, lba48, cnt48, ide_mult); },
        0x30, 0x31 => { ide_rw(true, lba, cnt, 1); },
        0xC5 => { ide_rw(true, lba, cnt, ide_mult); },
        0x34 => { ide_rw(true, lba48, cnt48, 1); },
        0x39 => { ide_rw(true, lba48, cnt48, ide_mult); },
        0xC6 => {
            // SET MULTIPLE MODE: a power of two up to sixteen.
            let n = ide_cnt[0];
            if n == 1 || n == 2 || n == 4 || n == 8 || n == 16 { ide_mult = n; ide_done(0); } else { ide_done(4); }
        },
        0xE5 => { ide_cnt[0] = 0xFF; ide_done(0); },                 // CHECK POWER MODE: active
        0x90 => { ide_reset(); ide_irq(); },                        // EXECUTE DEVICE DIAGNOSTIC
        // Nothing to do: verify, recalibrate, seek, set the geometry or a feature, the
        // power commands, flush.
        0x40, 0x41, 0x42, 0x10, 0x70, 0x91, 0xEF, 0xE0, 0xE1, 0xE2, 0xE3, 0xE6, 0xE7, 0xEA => { ide_done(0); },
        _ => { ide_done(4); },                                      // aborted
    }
}

// A byte from the data port.
fn ide_data_in() -> u8 {
    if ide_mode != 1 { return 0; }
    let b = ide_buf[ide_pos];
    ide_pos += 1;
    if ide_pos >= ide_end {
        if ide_left > 0 { ide_load(); } else { ide_mode = 0; ide_status = 0x50; }
    }
    return b;
}

// A byte to the data port. When the block is whole it goes to the disk.
fn ide_data_out(v: u8) {
    if ide_mode != 2 { return; }
    ide_buf[ide_pos] = v;
    ide_pos += 1;
    if ide_pos < ide_end { return; }
    let n = ide_end / 512;
    if disk_write(ide_next, ide_buf[..ide_end]) != 0 { ide_done(0x40); return; }
    ide_writes += n;
    ide_next += n;
    ide_left -= n;
    if ide_left <= 0 { ide_done(0); return; }
    ide_pos = 0;
    ide_end = (if ide_left < ide_blk { ide_left } else { ide_blk }) * 512;
    ide_status = 0x58;
    ide_irq();
}

// Registers 1 to 7 of the command block, and 8 for the control block's one.
fn ide_read(r: u16) -> u8 {
    if r == 0 { return ide_data_in(); }
    if ide_drive & 0x10 != 0 { return 0; }           // the slave: nothing there
    let before: i64 = if ide_ctl & 0x80 != 0 { 1 } else { 0 };
    match r {
        1 => { return ide_err; },
        2 => { return ide_cnt[before]; },
        3 => { return ide_lba[before * 3]; },
        4 => { return ide_lba[before * 3 + 1]; },
        5 => { return ide_lba[before * 3 + 2]; },
        6 => { return ide_drive; },
        7 => {
            // Reading the status takes the interrupt back.
            pic[1].irr &= ~0x40;
            pic_update();
            return ide_status;
        },
        _ => { return ide_status; },                 // the alternate status: the interrupt stays
    }
}

fn ide_write(r: u16, v: u8) {
    if r == 0 { ide_data_out(v); return; }
    if r == 8 {
        // The reset bit: busy while it is set, the signature when it falls.
        let was = ide_ctl & 4 != 0;
        ide_ctl = v;
        if was && v & 4 == 0 { ide_reset(); } else if v & 4 != 0 { ide_status = 0x80; }
        return;
    }
    ide_ctl &= 0x7F;
    match r {
        1 => { ide_feat = v; },
        2 => { ide_cnt[1] = ide_cnt[0]; ide_cnt[0] = v; },
        3 => { ide_lba[3] = ide_lba[0]; ide_lba[0] = v; },
        4 => { ide_lba[4] = ide_lba[1]; ide_lba[1] = v; },
        5 => { ide_lba[5] = ide_lba[2]; ide_lba[2] = v; },
        6 => { ide_drive = v; },
        _ => { if ide_drive & 0x10 == 0 { ide_command(v); } },
    }
}

// ---- PCI and the network card (only with --net) ----
//
// The kernel g86m boots drives an NE2000 only on PCI (ne2k-pci), so with --net the machine
// has a PCI bus: configuration mechanism 1 (an address written to port CF8h, the register
// read and written at CFCh), a host bridge at device 0 so that the bus is believed, and
// the card, a Realtek RTL8029, at device 3. Its thirty-two ports and its interrupt line
// are in its configuration, as firmware would have left them, and the guest may move the
// ports. Without --net none of this is there. As rustx86's bus/pci and card/rtl8029.

extern fn net_open() -> i32;
extern fn net_send(frame: const u8[:]);
extern fn net_poll();
extern fn net_recv(buf: u8[:]) -> i32;

let NET_IRQ = 3;
var net_on = false;
var pci_addr: u32 = 0;
var pci_cfg: u8[512] = [0; 512];     // the bridge's 256 bytes, then the card's

fn pci_setup() {
    // The bridge: Intel 440FX, class 06 00.
    pci_cfg[0] = 0x86; pci_cfg[1] = 0x80; pci_cfg[2] = 0x37; pci_cfg[3] = 0x12;
    pci_cfg[0x0B] = 0x06;
    // The card: Realtek 8029, class 02 00, ports at C000h, interrupt line 3 on pin A.
    let c = 256;
    pci_cfg[c] = 0xEC; pci_cfg[c + 1] = 0x10; pci_cfg[c + 2] = 0x29; pci_cfg[c + 3] = 0x80;
    pci_cfg[c + 0x0B] = 0x02;
    pci_cfg[c + 0x10] = 0x01; pci_cfg[c + 0x11] = 0xC0;
    pci_cfg[c + 0x2C] = 0xEC; pci_cfg[c + 0x2D] = 0x10; pci_cfg[c + 0x2E] = 0x29; pci_cfg[c + 0x2F] = 0x80;
    pci_cfg[c + 0x3C] = NET_IRQ; pci_cfg[c + 0x3D] = 1;
}

// Where in pci_cfg the function the address names is, or -1: bus 0, device 0 or 3, function 0.
fn pci_slot() -> i64 {
    if pci_addr & 0x80000000 == 0 || pci_addr >> 16 & 0xFF != 0 || pci_addr >> 8 & 7 != 0 { return -1; }
    let dev = pci_addr >> 11 & 31;
    if dev == 0 { return 0; }
    if dev == 3 { return 256; }
    return -1;
}

fn pci_read(port: u16) -> u8 {
    if port < 0xCFC { return (pci_addr >> ((port - 0xCF8) * 8)) as! u8; }
    let s = pci_slot();
    if s < 0 { return 0xFF; }
    return pci_cfg[s + (pci_addr & 0xFC) + (port & 3)];
}

fn pci_write(port: u16, v: u8) {
    if port < 0xCFC {
        let sh: u32 = (port - 0xCF8) * 8;
        let b: u32 = v;
        pci_addr = pci_addr & ~(0xFF << sh) | b << sh;
        return;
    }
    let s = pci_slot();
    if s < 0 { return; }
    let r: i64 = (pci_addr & 0xFC) + (port & 3);
    // What can be written: the command register's low byte, the interrupt line, and of the
    // card its first base address, which stays a block of 32 ports whatever is written
    // (all ones written and read back is how its size is asked).
    if r == 0x04 || r == 0x3C { pci_cfg[s + r] = v; }
    else if s == 256 && r >= 0x10 && r < 0x14 {
        pci_cfg[s + r] = v;
        pci_cfg[s + 0x10] = pci_cfg[s + 0x10] & 0xE0 | 1;
    }
}

// The card's first port, or 0 while the command register keeps its ports off.
fn ne_base() -> u16 {
    if pci_cfg[256 + 4] & 1 == 0 { return 0; }
    let lo: u16 = pci_cfg[256 + 0x10] & 0xE0;
    let hi: u16 = pci_cfg[256 + 0x11];
    return hi << 8 | lo;
}

// The card's chip, a DP8390: sixteen registers in pages chosen by the command register's
// top bits, a data port through which the host reaches the chip's memory (the address PROM
// at 0, the buffers from 4000h to 8000h), and a reset port. A frame to send is handed to
// net_send at once. Frames for the guest are put in the receive ring, 256 bytes to a page,
// behind a header of four bytes each, for as long as the ring has room.
let NE_RAM = 0x4000;
let NE_END = 0x8000;
var ne_mem: u8[NE_END] = [0; NE_END];
var ne_pend: u8[1600] = [0; 1600];   // a frame taken from the host that the ring had no room for
var ne_pend_len: i64 = 0;
var ne_par: u8[6] = [0; 6];
var ne_mar: u8[8] = [0; 8];
var ne_rsar: u16 = 0;
var ne_rbcr: u16 = 0;
var ne_tbcr: u16 = 0;
var ne_cr: u8 = 1;                   // stopped
var ne_isr: u8 = 0x80;               // reset
var ne_imr: u8 = 0;
var ne_dcr: u8 = 0;
var ne_tcr: u8 = 0;
var ne_rcr: u8 = 0;
var ne_tpsr: u8 = 0;
var ne_pstart: u8 = 0;
var ne_pstop: u8 = 0;
var ne_bnry: u8 = 0;
var ne_curr: u8 = 0;
var ne_running = false;
var ne_sent: i64 = 0;                // frames each way, for the report
var ne_got: i64 = 0;

fn ne_setup() {
    // The address PROM: the station address, and two 57h that say an NE2000.
    let mac: u8[6] = [0x52, 0x54, 0x00, 0x12, 0x34, 0x56];
    for i in 6 { ne_mem[i] = mac[i]; }
    ne_mem[14] = 0x57;
    ne_mem[15] = 0x57;
}

// The interrupt line follows the status bits the mask lets through.
fn ne_irq() {
    if ne_isr & ne_imr & 0x7F != 0 { raise_irq(NET_IRQ); }
    else { pic[0].irr &= ~(1 << NET_IRQ); pic_update(); }
}

// One frame into the receive ring, if it has the pages.
fn ne_ring_put(len0: i64) -> bool {
    if !ne_running || ne_pstart >= ne_pstop { return false; }
    let len = if len0 < 60 { 60 } else { len0 };
    let total = 4 + len;
    let pages: i64 = (total + 255) / 256;
    let ring: i64 = ne_pstop - ne_pstart;
    let curr: i64 = ne_curr;
    let bnry: i64 = ne_bnry;
    let used = (curr + ring - bnry) % ring;
    if pages + 1 > ring - used { return false; }
    var next = curr + pages;
    if next >= ne_pstop { next = ne_pstart + (next - ne_pstop); }
    let stop: i64 = ne_pstop;
    let start: i64 = ne_pstart;
    var at = curr * 256;
    for i in total {
        var b: u8 = 0;
        if i == 0 { b = 1; }                                 // received whole
        else if i == 1 { b = next as! u8; }
        else if i == 2 { b = total as! u8; }
        else if i == 3 { b = (total >> 8) as! u8; }
        else if i - 4 < len0 { b = ne_pend[i - 4]; }
        if at < NE_END { ne_mem[at] = b; }
        at += 1;
        if at >= stop * 256 { at = start * 256; }
    }
    ne_curr = next as! u8;
    ne_isr |= 1;
    return true;
}

// Frames from the host into the ring, while there are any and there is room.
fn ne_drain() {
    loop {
        if ne_pend_len == 0 {
            ne_pend_len = net_recv(ne_pend[..]);
            if ne_pend_len == 0 { break; }
            // Not for this station, and the card is not listening to everything: dropped.
            var mine = ne_rcr & 0x10 != 0;
            if !mine {
                var own = true;
                var all = true;
                for i in 6 {
                    if ne_pend[i] != ne_par[i] { own = false; }
                    if ne_pend[i] != 0xFF { all = false; }
                }
                mine = own || all;
            }
            if !mine || !ne_running { ne_pend_len = 0; continue; }
        }
        if !ne_ring_put(ne_pend_len) { break; }
        ne_pend_len = 0;
        ne_got += 1;
    }
    ne_irq();
}

// What the run loop does for the network every so often.
fn net_tick() {
    net_poll();
    ne_drain();
}

fn ne_read(off: u16) -> u8 {
    if off == 0 { return ne_cr; }
    if off >= 0x18 {
        // The reset port.
        ne_isr |= 0x80;
        ne_cr = ne_cr & ~2 | 1;
        ne_running = false;
        return 0;
    }
    if off >= 0x10 {
        let v: u8 = if ne_rsar < NE_END { ne_mem[ne_rsar] } else { 0xFF };
        ne_rsar += 1;
        if ne_rbcr > 0 { ne_rbcr -= 1; }
        if ne_rbcr == 0 { ne_isr |= 0x40; ne_irq(); }
        return v;
    }
    if ne_cr >> 6 == 0 {
        if off == 3 { return ne_bnry; }
        if off == 4 { return 1; }                            // every frame is sent
        if off == 7 { return ne_isr; }
        return 0;
    }
    if ne_cr >> 6 == 1 {
        if off >= 1 && off <= 6 { return ne_par[off - 1]; }
        if off == 7 { return ne_curr; }
        if off >= 8 { return ne_mar[off - 8]; }
    }
    return 0;
}

fn ne_write(off: u16, v: u8) {
    if off == 0 {
        ne_cr = v & ~4;
        if v & 2 != 0 { ne_isr &= 0x7F; ne_running = true; }
        else if v & 1 != 0 { ne_isr |= 0x80; ne_running = false; }
        if v & 4 != 0 {
            // Transmit: the frame is in the chip's memory at page TPSR.
            let start: i64 = ne_tpsr;
            let from = start * 256;
            let len: i64 = ne_tbcr;
            if from >= NE_RAM && from + len <= NE_END && len > 0 { net_send(ne_mem[from..from + len]); ne_sent += 1; }
            ne_isr |= 2;
        }
        ne_irq();
        return;
    }
    if off >= 0x18 { ne_isr |= 0x80; ne_running = false; return; }
    if off >= 0x10 {
        if ne_rsar >= NE_RAM && ne_rsar < NE_END { ne_mem[ne_rsar] = v; }
        ne_rsar += 1;
        if ne_rbcr > 0 { ne_rbcr -= 1; }
        if ne_rbcr == 0 { ne_isr |= 0x40; ne_irq(); }
        return;
    }
    let w: u16 = v;
    if ne_cr >> 6 == 0 {
        match off {
            1 => { ne_pstart = v; },
            2 => { ne_pstop = v; },
            3 => { ne_bnry = v; ne_drain(); },
            4 => { ne_tpsr = v; },
            5 => { ne_tbcr = ne_tbcr & 0xFF00 | w; },
            6 => { ne_tbcr = ne_tbcr & 0x00FF | w << 8; },
            7 => { ne_isr &= ~v; ne_irq(); },
            8 => { ne_rsar = ne_rsar & 0xFF00 | w; },
            9 => { ne_rsar = ne_rsar & 0x00FF | w << 8; },
            10 => { ne_rbcr = ne_rbcr & 0xFF00 | w; },
            11 => { ne_rbcr = ne_rbcr & 0x00FF | w << 8; },
            12 => { ne_rcr = v; },
            13 => { ne_tcr = v; },
            14 => { ne_dcr = v; },
            _ => { ne_imr = v; ne_irq(); },
        }
        return;
    }
    if ne_cr >> 6 == 1 {
        if off >= 1 && off <= 6 { ne_par[off - 1] = v; }
        else if off == 7 { ne_curr = v; }
        else if off >= 8 { ne_mar[off - 8] = v; }
    }
}

// ---- Port dispatch ----


fn note_unknown(port: u16) {
    if unknown_ports[port] < 255 { unknown_ports[port] += 1; }
}

fn port_in8(port: u16) -> u8 {
    match port {
        0x20 => { return if pic[0].read_isr { pic[0].isr } else { pic[0].irr }; },
        0x21 => { return pic[0].imr; },
        0xA0 => { return if pic[1].read_isr { pic[1].isr } else { pic[1].irr }; },
        0xA1 => { return pic[1].imr; },
        0x40..0x43 => { return pit_read(port - 0x40); },
        0x60 => { return kbd_read_data(); },
        0x61 => {
            // Bits 0-3 read back as written; bit 4 toggles on every read (the refresh signal
            // of the original PC); bit 5 is timer channel 2's output.
            refresh ^= 0x10;
            return port_b & 0x0F | refresh | (if ch2_out() { 0x20 } else { 0 });
        },
        0x64 => { return if !kbd_full { 0x1C } else if kbd_out_aux { 0x3D } else { 0x1D }; },
        0x70 => { return cmos_index; },
        0x71 => { return cmos_read(); },
        0x1F0..0x1F8 => { if ide_sectors > 0 { return ide_read(port - 0x1F0); } note_unknown(port); return 0xFF; },
        0x3F6 => { if ide_sectors > 0 { return ide_read(8); } note_unknown(port); return 0xFF; },
        0x3D4 => { return crtc_index; },
        0x3D5 => { return crtc[crtc_index & 31]; },
        0x3DA => { retrace ^= 0x09; return retrace; },
        0x3F8..0x400 => { return com_read(port - 0x3F8); },
        0xCF8..0xD00 => { if net_on { return pci_read(port); } note_unknown(port); return 0xFF; },
        _ => {
            if net_on {
                let b = ne_base();
                if b != 0 && port >= b && port < b + 32 { return ne_read(port - b); }
            }
            note_unknown(port);
            return 0xFF;
        },
    }
}

fn port_out8(port: u16, v: u8) {
    match port {
        0x20 => { pic_command(0, v); },
        0x21 => { pic_data(0, v); },
        0xA0 => { pic_command(1, v); },
        0xA1 => { pic_data(1, v); },
        0x40..0x43 => { pit_write(port - 0x40, v); },
        0x43 => { pit_control(v); },
        0x60 => { kbd_write_data(v); },
        0x61 => { port_b = v; },
        0x64 => { kbd_write_command(v); },
        0x70 => { cmos_index = v & 0x7F; },      // the top bit masks the NMI, which there is none of
        0x71 => { cmos_write(v); },
        0x1F0..0x1F8 => { if ide_sectors > 0 { ide_write(port - 0x1F0, v); } else { note_unknown(port); } },
        0x3F6 => { if ide_sectors > 0 { ide_write(8, v); } else { note_unknown(port); } },
        0x3D4 => { crtc_index = v; },
        0x3D5 => { crtc[crtc_index & 31] = v; },
        0x190 => { post_trail.push(v); },
        0x3F8..0x400 => { com_write(port - 0x3F8, v); },
        0xCF8..0xD00 => { if net_on { pci_write(port, v); } else { note_unknown(port); } },
        _ => {
            if net_on {
                let b = ne_base();
                if b != 0 && port >= b && port < b + 32 { ne_write(port - b, v); return; }
            }
            note_unknown(port);
        },
    }
}

fn port_in(port: u16) -> u16 {
    let lo: u16 = port_in8(port);
    // The disk's data port is one port at every width.
    let hi: u16 = port_in8(if port == 0x1F0 { port } else { port + 1 });
    return lo | hi << 8;
}

fn port_out(port: u16, v: u16) {
    port_out8(port, v as! u8);
    port_out8(if port == 0x1F0 { port } else { port + 1 }, (v >> 8) as! u8);
}
