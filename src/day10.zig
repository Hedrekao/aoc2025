const std = @import("std");
const utils = @import("./utils.zig");
const c = @cImport({
    @cInclude("z3.h");
});

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

const Instance = struct {
    target: []bool,
    buttons: [][]usize,
    joltage: []usize,
};

fn parseInput(allocator: std.mem.Allocator, lines: *utils.LineIterator) ![]Instance {
    var list = std.ArrayList(Instance).empty;
    while (lines.next()) |line| {
        var elements = std.mem.splitScalar(u8, line, ' ');
        const target_str = elements.next().?;
        var target = std.ArrayList(bool).empty;

        var instance: Instance = undefined;
        for (target_str[1 .. target_str.len - 1]) |char| {
            try target.append(allocator, switch (char) {
                '.' => false,
                '#' => true,
                else => return error.InvalidInput,
            });
        }

        instance.target = try target.toOwnedSlice(allocator);

        var buttons = std.ArrayList([]usize).empty;
        while (elements.next()) |str| {
            if (str[0] == '(') {
                var numbers_str = std.mem.splitScalar(u8, str[1 .. str.len - 1], ',');
                var button = std.ArrayList(usize).empty;
                while (numbers_str.next()) |num_str| {
                    const num = try std.fmt.parseInt(usize, num_str, 10);
                    try button.append(allocator, num);
                }
                try buttons.append(allocator, try button.toOwnedSlice(allocator));
            } else {
                var joltage = std.ArrayList(usize).empty;
                var numbers_str = std.mem.splitScalar(u8, str[1 .. str.len - 1], ',');
                while (numbers_str.next()) |num_str| {
                    const num = try std.fmt.parseInt(usize, num_str, 10);
                    try joltage.append(allocator, num);
                }
                const joltage_slice = try joltage.toOwnedSlice(allocator);
                instance.joltage = joltage_slice;
            }
        }
        instance.buttons = try buttons.toOwnedSlice(allocator);
        try list.append(allocator, instance);
    }

    return try list.toOwnedSlice(allocator);
}

const BoolSliceContext = struct {
    pub fn hash(self: @This(), key: []const bool) u64 {
        _ = self;
        return std.hash.Wyhash.hash(0, std.mem.sliceAsBytes(key));
    }
    pub fn eql(self: @This(), a: []const bool, b: []const bool) bool {
        _ = self;
        return std.mem.eql(bool, a, b);
    }
};

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    const instances = try parseInput(allocator, lines);

    var result: usize = 0;

    for (instances) |instance| {
        var q = try utils.Queue([]bool).init(allocator, 1024);
        defer q.deinit();
        const start = try allocator.alloc(bool, instance.target.len);
        @memset(start, false);
        try q.enqueue(start);

        var visited = std.HashMap([]const bool, usize, BoolSliceContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer visited.deinit();

        try visited.put(start, 0);
        var done: bool = false;

        while (true) {
            const current = q.dequeue();
            if (current == null) break;
            const state = current.?;
            const times = visited.get(state).? + 1;

            for (instance.buttons) |button| {
                const next = try allocator.alloc(bool, state.len);
                @memcpy(next, state);

                for (button) |pos| {
                    next[pos] = !next[pos];
                }
                if (std.mem.eql(bool, next, instance.target)) {
                    result += times;
                    done = true;
                    break;
                } else {
                    if (visited.get(next) == null) {
                        try q.enqueue(next);
                        try visited.put(next, times);
                    }
                }
            }

            if (done) break;
        }
    }

    std.debug.print("Part 1: {}\n", .{result});
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    const instances = try parseInput(allocator, lines);

    var result: usize = 0;
    for (instances) |instance| {
        const ctx = c.Z3_mk_context(null);
        const opt = c.Z3_mk_optimize(ctx);
        const int_sort = c.Z3_mk_int_sort(ctx);

        const button_vars = try allocator.alloc(?*c.struct__Z3_ast, instance.buttons.len);

        const z3_zero = c.Z3_mk_int(ctx, 0, int_sort);

        for (0..instance.buttons.len) |i| {
            const symbol = c.Z3_mk_int_symbol(ctx, @intCast(i));
            const variable = c.Z3_mk_const(ctx, symbol, int_sort);
            button_vars[i] = variable;
            c.Z3_optimize_assert(ctx, opt, c.Z3_mk_ge(ctx, variable, z3_zero));
        }

        for (instance.joltage, 0..) |joltage, i| {
            const target = c.Z3_mk_int(ctx, @intCast(joltage), int_sort);

            var used_buttons = std.ArrayList(usize).empty;
            for (instance.buttons, 0..) |button, j| {
                for (button) |idx| {
                    if (idx == i) {
                        try used_buttons.append(allocator, j);
                        break;
                    }
                }
            }
            const z3_buttons = try allocator.alloc(?*c.struct__Z3_ast, used_buttons.items.len);
            for (used_buttons.items, 0..) |var_idx, idx| {
                z3_buttons[idx] = button_vars[var_idx];
            }

            c.Z3_optimize_assert(ctx, opt, c.Z3_mk_eq(ctx, target, c.Z3_mk_add(ctx, @intCast(z3_buttons.len), z3_buttons.ptr)));
        }

        const presses = c.Z3_mk_add(ctx, @intCast(button_vars.len), button_vars.ptr);
        _ = c.Z3_optimize_minimize(ctx, opt, presses);

        const opt_result = c.Z3_optimize_check(ctx, opt, 0, null);

        if (opt_result == c.Z3_L_TRUE) {
            const model = c.Z3_optimize_get_model(ctx, opt);

            var min_value_ast: ?*c.struct__Z3_ast = null;
            const success = c.Z3_model_eval(ctx, model, presses, true, &min_value_ast);

            if (success != false and min_value_ast != null) {
                const min_value_str = c.Z3_get_numeral_string(ctx, min_value_ast.?);
                const min_value = try std.fmt.parseInt(usize, std.mem.span(min_value_str), 10);
                result += min_value;
            }
        }

        c.Z3_del_context(ctx);
    }

    std.debug.print("Part 2: {}\n", .{result});
}
