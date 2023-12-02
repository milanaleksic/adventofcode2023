const std = @import("std");
const fs = std.fs;
const allocator = std.heap.page_allocator;

pub fn openFile(inputFile: []const u8, list: *std.ArrayList([]const u8)) !void {
    var file = try fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const buf2 = try allocator.dupe(u8, line);
        try list.append(buf2);
    }
}

pub fn parseToListOfStrings(comptime T: type, input: T) !std.ArrayList(T) {
    var list = std.ArrayList(T).init(std.testing.allocator);
    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |line| {
        try list.append(line);
    }
    return list;
}
