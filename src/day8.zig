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

const Point3D = struct {
    x: i32,
    y: i32,
    z: i32,
};

const Distance = struct {
    distance: f64,
    p1: Point3D,
    p2: Point3D,
};

fn distanceCompareFn(_: void, a: Distance, b: Distance) std.math.Order {
    if (a.distance < b.distance) return .lt;
    if (a.distance > b.distance) return .gt;
    return .eq;
}

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var points_list = std.ArrayList(Point3D).empty;
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ',');
        const x_str = it.next() orelse return error.InvalidInput;
        const y_str = it.next() orelse return error.InvalidInput;
        const z_str = it.next() orelse return error.InvalidInput;

        const x = try std.fmt.parseInt(i32, x_str, 10);
        const y = try std.fmt.parseInt(i32, y_str, 10);
        const z = try std.fmt.parseInt(i32, z_str, 10);

        try points_list.append(allocator, Point3D{
            .x = x,
            .y = y,
            .z = z,
        });
    }

    const points = try points_list.toOwnedSlice(allocator);

    var pq = std.PriorityQueue(Distance, void, distanceCompareFn).init(allocator, {});

    for (0..points.len) |i| {
        const p1 = points[i];
        for (i + 1..points.len) |j| {
            const p2 = points[j];
            const distance = std.math.sqrt(std.math.pow(f64, @floatFromInt(p2.x - p1.x), 2) +
                std.math.pow(f64, @floatFromInt(p2.y - p1.y), 2) +
                std.math.pow(f64, @floatFromInt(p2.z - p1.z), 2));
            try pq.add(Distance{
                .distance = distance,
                .p1 = p1,
                .p2 = p2,
            });
        }
    }

    var circuits = std.ArrayList(std.ArrayList(Point3D)).empty;
    const counter = 1000;

    for (0..counter) |_| {
        const d = pq.remove();
        const p1 = d.p1;
        const p2 = d.p2;

        var p1_circuit: isize = -1;
        var p2_circuit: isize = -1;

        for (0..circuits.items.len) |ci| {
            const circuit = circuits.items[ci];
            if (circuit.items.len == 0) continue;
            for (0..circuit.items.len) |pi| {
                const cp = circuit.items[pi];
                if (cp.x == p1.x and cp.y == p1.y and cp.z == p1.z) {
                    p1_circuit = @intCast(ci);
                }
                if (cp.x == p2.x and cp.y == p2.y and cp.z == p2.z) {
                    p2_circuit = @intCast(ci);
                }

                if (p1_circuit != -1 and p2_circuit != -1) break;
            }
            if (p1_circuit != -1 and p2_circuit != -1) break;
        }

        if (p1_circuit == -1 and p2_circuit == -1) {
            var new_circuit = std.ArrayList(Point3D).empty;
            try new_circuit.append(allocator, p1);
            try new_circuit.append(allocator, p2);
            try circuits.append(allocator, new_circuit);
            continue;
        }

        if (p1_circuit == p2_circuit) {
            continue;
        }

        if (p1_circuit != -1 and p2_circuit == -1) {
            var circuit = &circuits.items[@intCast(p1_circuit)];
            try circuit.append(allocator, p2);
        }

        if (p1_circuit == -1 and p2_circuit != -1) {
            var circuit = &circuits.items[@intCast(p2_circuit)];
            try circuit.append(allocator, p1);
        }

        if (p1_circuit != -1 and p2_circuit != -1) {
            const circuit2 = circuits.items[@intCast(p2_circuit)].items;

            try circuits.items[@intCast(p1_circuit)].appendSlice(allocator, circuit2);

            _ = circuits.swapRemove(@intCast(p2_circuit));
        }
    }

    var top1: usize = 1;
    var top2: usize = 1;
    var top3: usize = 1;
    for (try circuits.toOwnedSlice(allocator)) |ci| {
        const len = ci.items.len;
        if (len > top1) {
            top3 = top2;
            top2 = top1;
            top1 = len;
        } else if (len > top2) {
            top3 = top2;
            top2 = len;
        } else if (len > top3) {
            top3 = len;
        }
    }

    const result: usize = top1 * top2 * top3;

    std.debug.print("Part 1: {}\n", .{result});
}

fn compare_lists(_: void, a: std.ArrayList(Point3D), b: std.ArrayList(Point3D)) std.math.Order {
    if (a.items.len > b.items.len) return .lt;
    if (a.items.len < b.items.len) return .gt;
    return .eq;
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var points_list = std.ArrayList(Point3D).empty;
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ',');
        const x_str = it.next() orelse return error.InvalidInput;
        const y_str = it.next() orelse return error.InvalidInput;
        const z_str = it.next() orelse return error.InvalidInput;

        const x = try std.fmt.parseInt(i32, x_str, 10);
        const y = try std.fmt.parseInt(i32, y_str, 10);
        const z = try std.fmt.parseInt(i32, z_str, 10);

        try points_list.append(allocator, Point3D{
            .x = x,
            .y = y,
            .z = z,
        });
    }

    const points = try points_list.toOwnedSlice(allocator);
    const n_points = points.len;

    var pq = std.PriorityQueue(Distance, void, distanceCompareFn).init(allocator, {});

    for (0..points.len) |i| {
        const p1 = points[i];
        for (i + 1..points.len) |j| {
            const p2 = points[j];
            const distance = std.math.sqrt(std.math.pow(f64, @floatFromInt(p2.x - p1.x), 2) +
                std.math.pow(f64, @floatFromInt(p2.y - p1.y), 2) +
                std.math.pow(f64, @floatFromInt(p2.z - p1.z), 2));
            try pq.add(Distance{
                .distance = distance,
                .p1 = p1,
                .p2 = p2,
            });
        }
    }

    var max_queue = std.PriorityQueue(std.ArrayList(Point3D), void, compare_lists).init(allocator, {});

    while (true) {
        const d = pq.remove();
        const p1 = d.p1;
        const p2 = d.p2;

        var p1_circuit: isize = -1;
        var p2_circuit: isize = -1;

        for (0..max_queue.items.len) |ci| {
            const circuit = max_queue.items[ci];
            if (circuit.items.len == 0) continue;
            for (0..circuit.items.len) |pi| {
                const cp = circuit.items[pi];
                if (cp.x == p1.x and cp.y == p1.y and cp.z == p1.z) {
                    p1_circuit = @intCast(ci);
                }
                if (cp.x == p2.x and cp.y == p2.y and cp.z == p2.z) {
                    p2_circuit = @intCast(ci);
                }

                if (p1_circuit != -1 and p2_circuit != -1) break;
            }
            if (p1_circuit != -1 and p2_circuit != -1) break;
        }

        if (p1_circuit == -1 and p2_circuit == -1) {
            var new_circuit = std.ArrayList(Point3D).empty;
            try new_circuit.append(allocator, p1);
            try new_circuit.append(allocator, p2);
            try max_queue.add(new_circuit);
            continue;
        }

        if (p1_circuit == p2_circuit) {
            continue;
        }

        if (p1_circuit != -1 and p2_circuit == -1) {
            var circuit = &max_queue.items[@intCast(p1_circuit)];
            try circuit.append(allocator, p2);
        }

        if (p1_circuit == -1 and p2_circuit != -1) {
            var circuit = &max_queue.items[@intCast(p2_circuit)];
            try circuit.append(allocator, p1);
        }

        if (p1_circuit != -1 and p2_circuit != -1) {
            const circuit2 = max_queue.items[@intCast(p2_circuit)].items;

            try max_queue.items[@intCast(p1_circuit)].appendSlice(allocator, circuit2);

            _ = max_queue.removeIndex(@intCast(p2_circuit));
        }

        const peeked = max_queue.peek() orelse break;
        if (peeked.items.len == n_points) {
            std.debug.print("Part 2: {}\n", .{@as(usize, @intCast(p1.x)) * @as(usize, @intCast(p2.x))});
            break;
        }
    }
}
