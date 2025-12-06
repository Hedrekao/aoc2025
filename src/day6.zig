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

pub fn parse_number_string(list: *std.ArrayList(std.ArrayList(usize)), current_string: *std.ArrayList(u8), create_space: bool, number_idx: usize, allocator: std.mem.Allocator) !void {
    const number_str = try current_string.toOwnedSlice(allocator);
    const number = try std.fmt.parseInt(usize, number_str, 10);
    if (create_space) {
        const column = std.ArrayList(usize).empty;
        try list.append(allocator, column);
        try list.items[number_idx].append(allocator, number);
    } else {
        try list.items[number_idx].append(allocator, number);
    }
}

pub fn part1(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var result: usize = 0;
    var list = std.ArrayList(std.ArrayList(usize)).empty;
    var create_space = true;
    var current_string = std.ArrayList(u8).empty;
    var number_idx: usize = 0;

    while (lines.next()) |line| {
        for (line) |char| {
            if (char == ' ') {
                if (current_string.items.len == 0) continue;
                try parse_number_string(&list, &current_string, create_space, number_idx, allocator);
                number_idx += 1;
            } else if (char == '*') {
                var partial: usize = 1;
                const owned_slice = try list.items[number_idx].toOwnedSlice(allocator);
                for (owned_slice) |value| {
                    partial *= value;
                }
                result += partial;
                number_idx += 1;
            } else if (char == '+') {
                var partial: usize = 0;
                const owned_slice = try list.items[number_idx].toOwnedSlice(allocator);
                for (owned_slice) |value| {
                    partial += value;
                }
                result += partial;
                number_idx += 1;
            } else {
                try current_string.append(allocator, char);
            }
        }

        if (current_string.items.len != 0) {
            try parse_number_string(&list, &current_string, create_space, number_idx, allocator);
        }

        number_idx = 0;
        create_space = false;
    }

    std.debug.print("Part 1: {d}\n", .{result});
}

pub fn part2(lines: *utils.LineIterator, allocator: std.mem.Allocator) !void {
    var result: usize = 0;
    var list = std.ArrayList(std.ArrayList(usize)).empty;
    var max_size = std.ArrayList(usize).empty;
    var col_idx: usize = 0;
    var num_idx: usize = 0;
    var first_digit = false;
    var prev_char: u8 = 0;

    while (lines.next()) |line| {
        var current_len: usize = 0;

        for (line) |c| {
            if (c == '*' or c == '+') {
                break;
            }

            if (c != ' ') {
                if (first_digit and prev_char == ' ') {
                    if (col_idx >= max_size.items.len) {
                        try max_size.append(allocator, current_len);
                    } else if (current_len > max_size.items[col_idx]) {
                        max_size.items[col_idx] = current_len;
                    }
                    col_idx += 1;
                    current_len = 1;
                } else {
                    current_len += 1;
                }
                first_digit = true;
            }
            prev_char = c;
        }

        if (col_idx >= max_size.items.len) {
            try max_size.append(allocator, current_len);
        } else if (current_len > max_size.items[col_idx]) {
            max_size.items[col_idx] = current_len;
        }

        col_idx = 0;
        current_len = 0;
        first_digit = false;
    }

    try lines.reset();

    var reduction_phase = false;
    while (lines.next()) |line| {
        col_idx = 0;
        num_idx = 0;
        for (line) |c| {
            if (c == '*') {
                reduction_phase = true;
                var partial: usize = 1;
                const owned_slice = try list.items[col_idx].toOwnedSlice(allocator);
                for (owned_slice) |value| {
                    partial *= value;
                }
                result += partial;
                col_idx += 1;
            } else if (c == '+') {
                reduction_phase = true;
                var partial: usize = 0;
                const owned_slice = try list.items[col_idx].toOwnedSlice(allocator);
                for (owned_slice) |value| {
                    partial += value;
                }
                result += partial;
                col_idx += 1;
            } else if (!reduction_phase and num_idx < max_size.items[col_idx]) {
                const digit = if (c == ' ') 0 else c - '0';
                if (col_idx >= list.items.len) {
                    const column = std.ArrayList(usize).empty;
                    try list.append(allocator, column);
                }

                if (list.items[col_idx].items.len <= num_idx) {
                    try list.items[col_idx].append(allocator, digit);
                } else {
                    if (digit != 0) {
                        list.items[col_idx].items[num_idx] *= 10;
                    }
                    list.items[col_idx].items[num_idx] += digit;
                }

                num_idx += 1;
            } else if (!reduction_phase) {
                col_idx += 1;
                num_idx = 0;
            }
        }

        if (!reduction_phase and num_idx < max_size.items[col_idx]) {
            for (num_idx..max_size.items[col_idx]) |_| {
                if (list.items[col_idx].items.len <= num_idx) {
                    try list.items[col_idx].append(allocator, 0);
                }
            }
        }
    }

    std.debug.print("Part 2: {d}\n", .{result});
}
