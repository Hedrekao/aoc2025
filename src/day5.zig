const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = try utils.LineIterator.init(allocator);
    defer lines.deinit();

    try part1(&lines, allocator);
    try lines.reset();
    try part2(&lines, allocator);
}

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var result: usize = 0;
    var list = std.ArrayList([2]usize).empty;
    var collect_phase = true;

    while (lines.next()) |line| {
        if (line.len == 0) {
            collect_phase = false;
            continue;
        } else if (collect_phase) {
            var parts = std.mem.splitScalar(u8, line, '-');
            const start = try std.fmt.parseInt(usize, parts.next().?, 10);
            const end = try std.fmt.parseInt(usize, parts.next().?, 10);
            try list.append(allocator, .{ start, end });
        } else {
            const number = try std.fmt.parseInt(usize, line, 10);
            for (list.items) |range| {
                if (number >= range[0] and number <= range[1]) {
                    result += 1;
                    break;
                }
            }
        }
    }

    std.debug.print("Part 1: {d}\n", .{result});
}


fn compare (_: void, a: [2]usize, b: [2]usize) bool {
    return a[0] < b[0];
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var result: usize = 0;
    var list = std.ArrayList([2]usize).empty;

    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        } else {
            var parts = std.mem.splitScalar(u8, line, '-');
            const start = try std.fmt.parseInt(usize, parts.next().?, 10);
            const end = try std.fmt.parseInt(usize, parts.next().?, 10);

            try list.append(allocator, .{ start, end });
        }
    }


    std.mem.sort([2]usize, list.items, {}, compare);

    var final_ranges = std.ArrayList([2]usize).empty;
    var start = list.items[0][0];
    var end = list.items[0][1];

    for (list.items) |range| {
        if (range[0] <= end) {
            end = @max(end, range[1]);
        } else {
            try final_ranges.append(allocator, .{ start, end });
            start = range[0];
            end = range[1];
        }
    }

    try final_ranges.append(allocator, .{ start, end });

    for (final_ranges.items) |range| {
        result += range[1] - range[0] + 1;
    }

    std.debug.print("Part 2: {d}\n", .{result});
}
