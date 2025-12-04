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
    var list = std.ArrayList([]u8){};

    while (lines.next()) |line| {
        const line_copy = try allocator.dupe(u8, line);
        try list.append(allocator, line_copy);
    }

    const height: isize = @intCast(list.items.len);
    const width: isize = @intCast(list.items[0].len);

    const directions = [_][2]isize{
        [2]isize{ -1, -1 },
        [2]isize{ -1, 0 },
        [2]isize{ -1, 1 },
        [2]isize{ 0, -1 },
        [2]isize{ 0, 1 },
        [2]isize{ 1, -1 },
        [2]isize{ 1, 0 },
        [2]isize{ 1, 1 },
    };

    for (0..list.items.len) |_i| {
        const i: isize = @intCast(_i);
        const row = list.items[_i];
        for (0..row.len) |_j| {
            const j: isize = @intCast(_j);
            const c = row[_j];

            if (c != '@') continue;

            var adjacent_papers: usize = 0;

            for (directions) |dir| {
                const ni = i + dir[0];
                const nj = j + dir[1];
                if ((ni < 0 or ni >= height) or
                    (nj < 0 or nj >= width))
                {
                    continue;
                }

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
    var list = std.ArrayList([]u8){};

    while (lines.next()) |line| {
        const line_copy = try allocator.dupe(u8, line);
        try list.append(allocator, line_copy);
    }

    const height: isize = @intCast(list.items.len);
    const width: isize = @intCast(list.items[0].len);

    const directions = [_][2]isize{
        [2]isize{ -1, -1 },
        [2]isize{ -1, 0 },
        [2]isize{ -1, 1 },
        [2]isize{ 0, -1 },
        [2]isize{ 0, 1 },
        [2]isize{ 1, -1 },
        [2]isize{ 1, 0 },
        [2]isize{ 1, 1 },
    };

    while (true) {
        var removed: usize = 0;

        for (0..list.items.len) |_i| {
            const i: isize = @intCast(_i);
            const row = list.items[_i];
            for (0..row.len) |_j| {
                const j: isize = @intCast(_j);
                const c = row[_j];

                if (c != '@') continue;

                var adjacent_papers: usize = 0;

                for (directions) |dir| {
                    const ni = i + dir[0];
                    const nj = j + dir[1];
                    if ((ni < 0 or ni >= height) or
                        (nj < 0 or nj >= width))
                    {
                        continue;
                    }

                    if (list.items[@intCast(ni)][@intCast(nj)] == '@') {
                        adjacent_papers += 1;
                    }
                }

                if (adjacent_papers <= 3) {
                    list.items[_i][_j] = '.';
                    removed += 1;
                }
            }
        }
        if (removed == 0) break;
        result += removed;
    }

    std.debug.print("Part 2: {d}\n", .{result});
}
