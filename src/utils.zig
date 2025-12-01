const std = @import("std");

pub const LineIterator = struct {
    file: std.fs.File,
    buf: []u8,
    file_reader: std.fs.File.Reader,
    allocator: std.mem.Allocator,

    pub fn init(path: []const u8, allocator: std.mem.Allocator) !LineIterator {
        const file = try std.fs.cwd().openFile(path, .{});
        const buf = try allocator.alloc(u8, 1024);
        const file_reader = file.reader(buf);
        return LineIterator{
            .file = file,
            .buf = buf,
            .file_reader = file_reader,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: LineIterator) void {
        self.allocator.free(self.buf);
        self.file.close();
    }

    pub fn next(self: *LineIterator) ?[]u8 {
        const reader  = &self.file_reader.interface;
        return reader.takeDelimiter('\n') catch return null;
    }

    pub fn reset(self: *LineIterator) !void {
        try self.file.seekTo(0);
        self.file_reader = self.file.reader(self.buf);
    }
};
