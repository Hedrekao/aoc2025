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

fn parseInput(allocator: std.mem.Allocator, lines: *utils.LineIterator) !std.StringHashMap([][]const u8) {
    var map = std.StringHashMap([][]const u8).init(allocator);
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, &std.ascii.whitespace);
        if (line.len == 0) continue;

        var elements = std.mem.splitSequence(u8, line, ": ");
        const in_raw = elements.next().?;
        const in = try allocator.dupe(u8, in_raw);

        const rest = elements.next().?;
        var outputs_iter = std.mem.splitScalar(u8, rest, ' ');
        var tmp = std.ArrayList([]const u8).empty;

        while (outputs_iter.next()) |out| {
            const out_dup = try allocator.dupe(u8, out);
            try tmp.append(allocator, out_dup);
        }

        const outputs = try tmp.toOwnedSlice(allocator);

        try map.put(in, outputs);
    }

    return map;
}

fn dfs(instance: std.StringHashMap([][]const u8), current: []const u8, visited: *std.StringHashMap(bool), result: *usize) !void {
    if (std.mem.eql(u8, current, "out")) {
        result.* += 1;
        return;
    }

    const outputs = instance.get(current);
    if (outputs == null) return;

    try visited.put(current, true);
    defer _ = visited.remove(current);

    for (outputs.?) |next| {
        if (visited.get(next) == null) {
            try dfs(instance, next, visited, result);
        }
    }
}

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    const instance = try parseInput(allocator, lines);

    var result: usize = 0;

    var visited = std.StringHashMap(bool).init(allocator);
    defer visited.deinit();

    try dfs(instance, "svr", &visited, &result);

    std.debug.print("Part 1: {}\n", .{result});
}

const MemoKey = struct {
    node: []const u8,
    seen_fft: bool,
    seen_dac: bool,
};

const MemoContext = struct {
    pub fn hash(_: @This(), key: MemoKey) u64 {
        var h: u64 = 0;
        for (key.node) |c| {
            h = h *% 31 +% c;
        }
        h = h *% 31 +% @intFromBool(key.seen_fft);
        h = h *% 31 +% @intFromBool(key.seen_dac);
        return h;
    }
    pub fn eql(_: @This(), a: MemoKey, b: MemoKey) bool {
        return std.mem.eql(u8, a.node, b.node) and a.seen_fft == b.seen_fft and a.seen_dac == b.seen_dac;
    }
};

const MemoMap = std.HashMap(MemoKey, usize, MemoContext, std.hash_map.default_max_load_percentage);

fn dfs2(instance: std.StringHashMap([][]const u8), current: []const u8, seen_fft_prev: bool, seen_dac_prev: bool, memo: *MemoMap) !usize {
    const seen_fft = seen_fft_prev or std.mem.eql(u8, current, "fft");
    const seen_dac = seen_dac_prev or std.mem.eql(u8, current, "dac");

    if (std.mem.eql(u8, current, "out")) {
        if (seen_fft and seen_dac) return 1;
        return 0;
    }

    const key = MemoKey{ .node = current, .seen_fft = seen_fft, .seen_dac = seen_dac };
    if (memo.get(key)) |cached| {
        return cached;
    }

    const outputs = instance.get(current);
    if (outputs == null) return 0;

    var total: usize = 0;
    for (outputs.?) |next| {
        total += try dfs2(instance, next, seen_fft, seen_dac, memo);
    }

    try memo.put(key, total);
    return total;
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    const instance = try parseInput(allocator, lines);

    var memo = MemoMap.init(allocator);
    defer memo.deinit();

    const result = try dfs2(instance, "svr", false, false, &memo);

    std.debug.print("Part 2: {}\n", .{result});
}
