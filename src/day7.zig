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

const Point = struct {
    x: usize,
    y: usize,
};

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var grid_list = std.ArrayList([]u8).empty;
    while (lines.next()) |line| {
        try grid_list.append(allocator, try allocator.dupe(u8, line));
    }

    var split_map = std.hash_map.AutoHashMap(Point, bool).init(allocator);

    const grid = try grid_list.toOwnedSlice(allocator);

    var start: Point = undefined;
    for (0..grid[0].len) |x| {
        if (grid[0][x] == 'S') {
            start = Point{ .x = x, .y = 0 };
        }
    }

    var current_y: usize = 1;
    var result: usize = 0;
    var beams_x = std.ArrayList(usize).empty;
    try beams_x.append(allocator, start.x);
    while (current_y < grid.len) : (current_y += 1) {
        const x_values = try beams_x.toOwnedSlice(allocator);
        for (x_values) |x| {
            const cell = grid[current_y][x];
            if (cell == '.') {
                if (!split_map.contains(Point{ .x = x, .y = current_y })) {
                    try beams_x.append(allocator, x);
                    try split_map.put(Point{ .x = x, .y = current_y }, true);
                }
            } else if (cell == '^') {
                result += 1;
                if (x > 0) {
                    const point = Point{ .x = x - 1, .y = current_y };
                    if (!split_map.contains(point)) {
                        try beams_x.append(allocator, x - 1);
                        try split_map.put(point, true);
                    }
                }
                if (x + 1 < grid[0].len) {
                    const point = Point{ .x = x + 1, .y = current_y };
                    if (!split_map.contains(point)) {
                        try beams_x.append(allocator, x + 1);
                        try split_map.put(point, true);
                    }
                }
            } else {
                unreachable;
            }
        }
    }

    std.debug.print("Part 1: {}\n", .{result});
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var grid_list = std.ArrayList([]u8).empty;
    while (lines.next()) |line| {
        try grid_list.append(allocator, try allocator.dupe(u8, line));
    }

    const grid = try grid_list.toOwnedSlice(allocator);

    var split_map = std.hash_map.AutoHashMap(Point, usize).init(allocator);

    var start: Point = undefined;
    for (0..grid[0].len) |x| {
        if (grid[0][x] == 'S') {
            start = Point{ .x = x, .y = 0 };
        }
    }

    var timelines_x = std.ArrayList(usize).empty;
    try timelines_x.append(allocator, start.x);

    var current_y: usize = 1;
    while (current_y < grid.len) : (current_y += 1) {
        const x_values = try timelines_x.toOwnedSlice(allocator);
        for (x_values) |x| {
            const cell = grid[current_y][x];
            const prev_point_value = split_map.get(.{ .x = x, .y = current_y - 1 }) orelse 1;
            if (cell == '.') {
                const point = Point{ .x = x, .y = current_y };

                if (split_map.contains(point)) {
                    const existing_timeline = split_map.get(point).?;
                    try split_map.put(point, existing_timeline + prev_point_value);
                } else {
                    try split_map.put(point, prev_point_value);
                    try timelines_x.append(allocator, x);
                }
            } else if (cell == '^') {
                if (x > 0) {
                    const point_left = Point{ .x = x - 1, .y = current_y };
                    if (split_map.contains(point_left)) {
                        const existing_timeline = split_map.get(point_left).?;
                        try split_map.put(point_left, existing_timeline + prev_point_value);
                    } else {
                        try split_map.put(point_left, prev_point_value);
                        try timelines_x.append(allocator, x - 1);
                    }
                }
                if (x + 1 < grid[0].len) {
                    const point_right = Point{ .x = x + 1, .y = current_y };
                    if (split_map.contains(point_right)) {
                        const existing_timeline = split_map.get(point_right).?;
                        try split_map.put(point_right, existing_timeline + prev_point_value);
                    } else {
                        try split_map.put(point_right, prev_point_value);
                        try timelines_x.append(allocator, x + 1);
                    }
                }
            } else {
                unreachable;
            }
        }

    }

    var result: usize = 0;
    const x_values = try timelines_x.toOwnedSlice(allocator);
    for (x_values) |x| {
        const point = Point{ .x = x, .y = grid.len - 1 };
        const timelines = split_map.get(point).?;
        result += timelines;
    }

    std.debug.print("Part 2: {}\n", .{result});
}
