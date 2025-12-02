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
    var result: usize = 0;
    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');

        while (iter.next()) |range_str| {
            if (range_str.len == 0) continue;
            var range_iter = std.mem.splitScalar(u8, range_str, '-');
            const start_str = range_iter.next() orelse "";
            const end_str = range_iter.next() orelse "";

            const start_digits = start_str.len;
            const end_digits = end_str.len;

            const start = try std.fmt.parseInt(usize, start_str, 10);
            const end = try std.fmt.parseInt(usize, end_str, 10);

            var n_size = if (@mod(start_digits, 2) != 0) start_digits + 1 else start_digits;

            while (n_size <= end_digits) {
                const half_size = n_size / 2;
                const biggest = std.math.pow(usize, 10, half_size) - 1;
                var smallest = std.math.pow(usize, 10, half_size - 1);
                if (smallest == 0) smallest += 1;

                for (smallest..biggest + 1) |half_number| {
                    const number = (std.math.pow(usize, 10, half_size) * half_number) + half_number;

                    if (number >= start and number <= end) {
                        result += number;
                    }
                }

                n_size *= 2;
            }
        }
    }

    std.debug.print("Part 1: {d}\n", .{result});
}

pub fn part2(lines: *utils.LineIterator) !void {
    var result: usize = 0;
    var map = std.hash_map.AutoHashMap(usize, bool).init(std.heap.page_allocator);
    defer map.deinit();
    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');

        while (iter.next()) |range_str| {
            if (range_str.len == 0) continue;
            var range_iter = std.mem.splitScalar(u8, range_str, '-');
            const start_str = range_iter.next() orelse "";
            const end_str = range_iter.next() orelse "";

            const end_digits = end_str.len;

            const start = try std.fmt.parseInt(usize, start_str, 10);
            const end = try std.fmt.parseInt(usize, end_str, 10);

            var n_size: usize = 1;

            while (n_size <= @divFloor(end_digits, 2)) {
                const biggest = std.math.pow(usize, 10, n_size) - 1;
                var smallest = std.math.pow(usize, 10, n_size - 1);
                if (smallest == 0) smallest += 1;

                const max_repetitions = @divFloor(end_digits, n_size);

                for (smallest..biggest + 1) |part_number| {
                    for (1..max_repetitions + 1) |n_numbers| {
                        var number: usize = 0;

                        for (0..n_numbers) |i| {
                            number += part_number * std.math.pow(usize, 10, i * n_size);
                        }

                        if (number > 9 and number >= start and number <= end and !map.contains(number)) {
                            try map.put(number, true);
                            result += number;
                        }
                    }
                }

                n_size += 1;
            }
        }
    }

    std.debug.print("Part 2: {d}\n", .{result});
}
