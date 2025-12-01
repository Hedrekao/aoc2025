const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var lines = try utils.LineIterator.init("input/test.txt", allocator);
    defer lines.deinit();

    while (lines.next()) |line| {
        std.debug.print("Line: {s}\n", .{line});
    }

}
