const std = @import("std");
const fs = std.fs;

const FileData = struct {
    const Self = @This();
    lines: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .lines = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn append(self: *Self, line: []const u8) !void {
        try self.lines.append(line);
    }

    pub fn deinit(self: *Self) void {
        for (self.lines.items) |line| {
            self.lines.allocator.free(line);
        }
        self.lines.deinit();
    }
};

pub fn openFile(allocator: std.mem.Allocator, inputFile: []const u8) !FileData {
    var list = FileData.init(allocator);
    var file = try fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const buf2 = try allocator.dupe(u8, line);
        try list.append(buf2);
    }
    return list;
}

pub fn parseToListOfStrings(comptime T: type, input: T) !std.ArrayList(T) {
    var list = std.ArrayList(T).init(std.testing.allocator);
    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |line| {
        try list.append(line);
    }
    return list;
}
