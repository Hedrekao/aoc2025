const std = @import("std");

pub const LineIterator = struct {
    file: std.fs.File,
    buf: []u8,
    file_reader: std.fs.File.Reader,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !LineIterator {
        const folder_name = std.os.argv[1];
        const file_name =
            if (std.os.argv.len == 3 and std.mem.eql(u8, std.mem.span(std.os.argv[2]), "test"))
                "test.txt"
            else
                "input.txt";

        const path = try std.fmt.allocPrint(allocator, "input/{s}/{s}", .{ folder_name, file_name });
        defer allocator.free(path);

        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    std.debug.print("Error: File not found: {s}\n", .{path});
                    return err;
                },
                else => return err,
            }
        };

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
        const reader = &self.file_reader.interface;
        return reader.takeDelimiter('\n') catch return null;
    }

    pub fn reset(self: *LineIterator) !void {
        try self.file.seekTo(0);
        self.file_reader = self.file.reader(self.buf);
    }
};
