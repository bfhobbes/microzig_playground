const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;
const Pio = rp2xxx.pio.Pio;
const StateMachine = rp2xxx.pio.StateMachine;

const ws2812_program = blk: {
    @setEvalBranchQuota(5000);
    break :blk rp2xxx.pio.assemble(
        \\;
        \\; Copyright (c) 2020 Raspberry Pi (Trading) Ltd.
        \\;
        \\; SPDX-License-Identifier: BSD-3-Clause
        \\;
        \\.program ws2812
        \\.side_set 1
        \\
        \\.define public T1 2
        \\.define public T2 5
        \\.define public T3 3
        \\
        \\.wrap_target
        \\bitloop:
        \\    out x, 1       side 0 [T3 - 1] ; Side-set still takes place when instruction stalls
        \\    jmp !x do_zero side 1 [T1 - 1] ; Branch on the bit we shifted out. Positive pulse
        \\do_one:
        \\    jmp  bitloop   side 1 [T2 - 1] ; Continue driving high, for a long pulse
        \\do_zero:
        \\    nop            side 0 [T2 - 1] ; Or drive low, for a short pulse
        \\.wrap
    , .{}).get_program_by_name("ws2812");
};

const sleepTime = 50;
const pio: Pio = rp2xxx.pio.num(0);
const sm: StateMachine = .sm0;
// const led_pin = gpio.num(23);
const led_pin = gpio.num(22);

const colors = [_]u32{
    // 0x00ff00 << 8, // Red
    // 0xff0000 << 8, // Green
    // 0x0000ff << 8, // Blue
    // // 0x00ffff << 8, // ?
    // 0xff00ff << 8, // ?
    // 0xffff00 << 8, // ?
    0x000000 << 8, // ?
    0x00ee00 << 8, // ?
    //00dd00 << 8, // ?
    0x00cc00 << 8, // ?
    //00bb00 << 8, // ?
    0x00aa00 << 8, // ?
    //009900 << 8, // ?
    0x008800 << 8, // ?
    //007700 << 8, // ?
    0x006600 << 8, // ?
    //005500 << 8, // ?
    0x004400 << 8, // ?
    //003300 << 8, // ?
    0x002200 << 8, // ?
    //001100 << 8, // ?
    0x000000 << 8, // ?
    0x0000ee << 8, // ?
    //0000dd << 8, // ?
    0x0000cc << 8, // ?
    //0000bb << 8, // ?
    0x0000aa << 8, // ?
    //000099 << 8, // ?
    0x000088 << 8, // ?
    //000077 << 8, // ?
    0x000066 << 8, // ?
    //000055 << 8, // ?
    0x000044 << 8, // ?
    //000033 << 8, // ?
    0x000022 << 8, // ?
    //000011 << 8, // ?
    0x000000 << 8, // ?
    0xee0000 << 8, // ?
    //dd0000 << 8, // ?
    0xcc0000 << 8, // ?
    //bb0000 << 8, // ?
    0xaa0000 << 8, // ?
    //990000 << 8, // ?
    0x880000 << 8, // ?
    //770000 << 8, // ?
    0x660000 << 8, // ?
    //550000 << 8, // ?
    0x440000 << 8, // ?
    //330000 << 8, // ?
    0x220000 << 8, // ?
    //110000 << 8, // ?
};

pub fn main() void {
    pio.gpio_init(led_pin);
    pio.sm_set_pindir(sm, @intFromEnum(led_pin), 1, .out);

    const cycles_per_bit: comptime_int = ws2812_program.defines[0].value + //T1
        ws2812_program.defines[1].value + //T2
        ws2812_program.defines[2].value; //T3
    const div = @as(f32, @floatFromInt(rp2xxx.clock_config.sys.?.frequency())) /
        (800_000 * cycles_per_bit);

    pio.sm_load_and_start_program(sm, ws2812_program, .{
        .clkdiv = rp2xxx.pio.ClkDivOptions.from_float(div),
        .pin_mappings = .{
            .side_set = .{
                .base = @intFromEnum(led_pin),
                .count = 1,
            },
        },
        .shift = .{
            .out_shiftdir = .left,
            .autopull = true,
            .pull_threshold = 24,
            .join_tx = true,
        },
    }) catch unreachable;
    pio.sm_set_enabled(sm, true);

    var offset: u32 = 0;
    while (true) {
        var i: u32 = 0;
        while (i < colors.len) {
            pio.sm_blocking_write(sm, colors[(offset + i) % colors.len]); //red
            i += 1;
        }
        offset += 1;
        rp2xxx.time.sleep_ms(sleepTime);

        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //yellow
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //magenta
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //cyan
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // rp2xxx.time.sleep_ms(sleepTime);
        // pio.sm_blocking_write(sm, 0xff00ff << 8); //blue
        // pio.sm_blocking_write(sm, 0x00ff00 << 8); //red
        // pio.sm_blocking_write(sm, 0xff0000 << 8); //green
        // pio.sm_blocking_write(sm, 0x0000ff << 8); //blue
        // pio.sm_blocking_write(sm, 0xffff00 << 8); //red
        // pio.sm_blocking_write(sm, 0x00ffff << 8); //green
        // rp2xxx.time.sleep_ms(sleepTime);
    }
}
