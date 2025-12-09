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
    x: isize,
    y: isize,
};

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var points_list = std.ArrayList(Point).empty;
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ',');
        const x_str = it.next() orelse return error.InvalidInput;
        const y_str = it.next() orelse return error.InvalidInput;

        const x = try std.fmt.parseInt(i32, x_str, 10);
        const y = try std.fmt.parseInt(i32, y_str, 10);

        try points_list.append(allocator, Point{
            .x = x,
            .y = y,
        });
    }

    const points = try points_list.toOwnedSlice(allocator);

    var max_area: usize = 0;
    for (0..points.len - 1) |i| {
        const p1 = points[i];
        for (i + 1..points.len) |j| {
            const p2 = points[j];
            const width = @abs(p2.x - p1.x) + 1;
            const height = @abs(p2.y - p1.y) + 1;

            const area = width * height;
            if (area > max_area) {
                max_area = area;
            }
        }
    }

    std.debug.print("Part 1: {}\n", .{max_area});
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var points_list = std.ArrayList(Point).empty;
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ',');
        const x_str = it.next() orelse return error.InvalidInput;
        const y_str = it.next() orelse return error.InvalidInput;

        const x = try std.fmt.parseInt(i32, x_str, 10);
        const y = try std.fmt.parseInt(i32, y_str, 10);

        try points_list.append(allocator, Point{
            .x = x,
            .y = y,
        });
    }

    const points = try points_list.toOwnedSlice(allocator);

    var max_area: usize = 0;

    for (0..points.len) |i| {
        const p = points[i];
        for (i + 1..points.len) |j| {
            const next_p = points[j];

            const left_x = @min(p.x, next_p.x);
            const right_x = @max(p.x, next_p.x);
            const bottom_y = @min(p.y, next_p.y);
            const top_y = @max(p.y, next_p.y);

            // Check all 4 corners are inside or on the polygon
            const corners = [4]Point{
                .{ .x = left_x, .y = bottom_y },
                .{ .x = right_x, .y = bottom_y },
                .{ .x = right_x, .y = top_y },
                .{ .x = left_x, .y = top_y },
            };

            var enclosed = true;

            for (corners) |corner| {
                if (!isInsideOrOnPolygon(corner, points)) {
                    enclosed = false;
                    break;
                }
            }

            if (!enclosed) continue;

            // Check that no polygon edge crosses through the rectangle's interior
            for (0..points.len) |k| {
                const edge_p1 = points[k];
                const edge_p2 = if (k == points.len - 1) points[0] else points[k + 1];

                if (edge_p1.x == edge_p2.x) {
                    const edge_x = edge_p1.x;
                    const edge_min_y = @min(edge_p1.y, edge_p2.y);
                    const edge_max_y = @max(edge_p1.y, edge_p2.y);

                    if (edge_x > left_x and edge_x < right_x) {
                        if (edge_min_y < top_y and edge_max_y > bottom_y) {
                            enclosed = false;
                            break;
                        }
                    }
                }

                if (edge_p1.y == edge_p2.y) {
                    const edge_y = edge_p1.y;
                    const edge_min_x = @min(edge_p1.x, edge_p2.x);
                    const edge_max_x = @max(edge_p1.x, edge_p2.x);

                    if (edge_y > bottom_y and edge_y < top_y) {
                        if (edge_min_x < right_x and edge_max_x > left_x) {
                            enclosed = false;
                            break;
                        }
                    }
                }
            }

            if (!enclosed) continue;

            const width: usize = @intCast(right_x - left_x + 1);
            const height: usize = @intCast(top_y - bottom_y + 1);
            const area = width * height;
            if (area > max_area) {
                max_area = area;
            }
        }
    }

    std.debug.print("Part 2: {}\n", .{max_area});
}

fn isInsideOrOnPolygon(point: Point, polygon: []const Point) bool {
    const px = point.x;
    const py = point.y;

    for (0..polygon.len) |i| {
        const p1 = polygon[i];
        const p2 = if (i == polygon.len - 1) polygon[0] else polygon[i + 1];

        if (isPointOnSegment(point, p1, p2)) {
            return true;
        }
    }

    var crossings: usize = 0;

    for (0..polygon.len) |i| {
        const p1 = polygon[i];
        const p2 = if (i == polygon.len - 1) polygon[0] else polygon[i + 1];

        // Cast ray to the right (+x direction)
        if (p1.x == p2.x) {
            const edge_x = p1.x;
            const edge_min_y = @min(p1.y, p2.y);
            const edge_max_y = @max(p1.y, p2.y);

            // Ray from point going right crosses this edge if:
            // - edge is to the right of point (edge_x > px)
            // - point's y is within edge's y range (exclusive on one end to handle corners)
            if (edge_x > px and py >= edge_min_y and py < edge_max_y) {
                crossings += 1;
            }
        }
    }

    return crossings % 2 == 1;
}

fn isPointOnSegment(point: Point, p1: Point, p2: Point) bool {
    if (p1.x == p2.x) {
        if (point.x == p1.x) {
            const min_y = @min(p1.y, p2.y);
            const max_y = @max(p1.y, p2.y);
            return point.y >= min_y and point.y <= max_y;
        }
    } else if (p1.y == p2.y) {
        if (point.y == p1.y) {
            const min_x = @min(p1.x, p2.x);
            const max_x = @max(p1.x, p2.x);
            return point.x >= min_x and point.x <= max_x;
        }
    }
    return false;
}
