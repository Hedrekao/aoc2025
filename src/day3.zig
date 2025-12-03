const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var lines = try utils.LineIterator.init(allocator);
    defer lines.deinit();

    try part1(&lines);
    try lines.reset();
    try part2(&lines);
}

pub fn part1(lines: *utils.LineIterator) !void {
    var sum: usize = 0;
    while (lines.next()) |line| {
        var first_digit: u8 = 0;
        var second_digit: u8 = 0;
        for (line, 0..) |c, index| {
            const digit = c - '0';
            if (digit > first_digit and index < line.len - 1) {
                first_digit = digit;
                second_digit = 0;
            } else if (digit > second_digit) {
                second_digit = digit;
            }
        }
        const number = first_digit * 10 + second_digit;
        sum += number;
    }

    std.debug.print("Part 1: {d}\n", .{sum});
}

pub fn part2(lines: *utils.LineIterator) !void {
    var sum: usize = 0;
    while (lines.next()) |line| {
        var digits: [12]u8 = undefined;
        @memset(&digits, 0);

        for (line, 0..) |c, index| {
            const digit = c - '0';
            for (digits, 0..) |d, j| {
                if (digit > d and index < line.len - (digits.len - 1 - j)) {
                    digits[j] = digit;
                    const rest = digits[j + 1 ..];
                    @memset(rest, 0);
                    break;
                }
            }
        }

        var number: usize = 0;
        for (digits, 0..) |d, i| {
            number += d * std.math.pow(usize, 10, digits.len - i - 1);
        }
        sum += number;
    }

    std.debug.print("Part 2: {d}\n", .{sum});
}
