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
    var list = std.ArrayList([]u8).empty;

    while (lines.next()) |line| {
        try list.append(allocator, try allocator.dupe(u8, line));
    }

    const height: isize = @intCast(list.items.len);
    const width: isize = @intCast(list.items[0].len);

    const directions = [_][2]isize{
        .{ -1, -1 },
        .{ -1, 0 },
        .{ -1, 1 },
        .{ 0, -1 },
        .{ 0, 1 },
        .{ 1, -1 },
        .{ 1, 0 },
        .{ 1, 1 },
    };

    for (0..list.items.len) |i| {
        const row = list.items[i];
        for (0..row.len) |j| {
            const c = row[j];

            if (c != '@') continue;

            var adjacent_papers: usize = 0;

            for (directions) |dir| {
                const ni = @as(isize, @intCast(i)) + dir[0];
                const nj = @as(isize, @intCast(j)) + dir[1];

                if (ni < 0 or ni >= height or nj < 0 or nj >= width) continue;

                if (list.items[@intCast(ni)][@intCast(nj)] == '@') {
                    adjacent_papers += 1;
                }
            }

            if (adjacent_papers <= 3) {
                result += 1;
            }
        }
    }

    std.debug.print("Part 1: {d}\n", .{result});
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var result: usize = 0;
    var list = std.ArrayList([]u8).empty;

    while (lines.next()) |line| {
        try list.append(allocator, try allocator.dupe(u8, line));
    }

    const height: isize = @intCast(list.items.len);
    const width: isize = @intCast(list.items[0].len);

    const directions = [_][2]isize{
        .{ -1, -1 },
        .{ -1, 0 },
        .{ -1, 1 },
        .{ 0, -1 },
        .{ 0, 1 },
        .{ 1, -1 },
        .{ 1, 0 },
        .{ 1, 1 },
    };

    while (true) {
        var removed: usize = 0;

        for (0..list.items.len) |i| {
            const row = list.items[i];
            for (0..row.len) |j| {
                const c = row[j];

                if (c != '@') continue;

                var adjacent_papers: usize = 0;

                for (directions) |dir| {
                    const ni = @as(isize, @intCast(i)) + dir[0];
                    const nj = @as(isize, @intCast(j)) + dir[1];
                    if (ni < 0 or ni >= height or nj < 0 or nj >= width) continue;

                    if (list.items[@intCast(ni)][@intCast(nj)] == '@') {
                        adjacent_papers += 1;
                    }
                }

                if (adjacent_papers <= 3) {
                    list.items[i][j] = '.';
                    removed += 1;
                }
            }
        }

        if (removed == 0) break;
        result += removed;
    }

    std.debug.print("Part 2: {d}\n", .{result});
}
