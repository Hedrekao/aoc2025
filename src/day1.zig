const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var lines = try utils.LineIterator.init("input/day1/input.txt", allocator);
    defer lines.deinit();

    try part1(&lines);
    try lines.reset();
    try part2(&lines);
}

pub fn part1(lines: *utils.LineIterator) !void {
    const mod: i32 = 100;
    var result: i32 = 0;
    var current: i32 = 50;
    while (lines.next()) |line| {
        const letter = line[0];
        const number = @mod(try std.fmt.parseInt(i32, line[1..], 10), mod);
        if (letter == 'L') {
            current -= number;
            if (current < 0) {
                current += mod;
            }
        } else if (letter == 'R') {
            current += number;
            if (current >= mod) {
                current -= mod;
            }
        } else {
            unreachable;
        }

        if (current == 0) {
            result += 1;
        }
    }

    std.debug.print("PART1: Final position: {}\n", .{current});
    std.debug.print("PART1: Number of times at position 0: {}\n", .{result});
}

pub fn part2(lines: *utils.LineIterator) !void {
    const mod: i32 = 100;
    var result: i32 = 0;
    var current: i32 = 50;
    while (lines.next()) |line| {
        const letter = line[0];
        const raw_number = try std.fmt.parseInt(i32, line[1..], 10);
        const n_cycles = @divTrunc(raw_number, mod);
        const mod_number = @mod(raw_number, mod);
        const is_zero = current == 0;

        if (letter == 'L') {
            current -= mod_number;
            if (current < 0) {
                current += mod;
                if (!is_zero and current != 0) {
                    result += 1;
                }
            }
        } else if (letter == 'R') {
            current += mod_number;
            if (current >= mod) {
                current -= mod;
                if (!is_zero and current != 0) {
                    result += 1;
                }
            }
        } else {
            unreachable;
        }

        result += n_cycles;

        if (current == 0) {
            result += 1;
        }
    }

    std.debug.print("PART2: Final position: {}\n", .{current});
    std.debug.print("PART2: Number of times at position 0: {}\n", .{result});
}
