const std = @import("std");
const fs = std.fs;

pub const InputMatrix = struct {
    const Self = @This();
    data: [][]u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        const cols = list.items[0].len;
        const rows = list.items.len;
        var data: [][]u8 = try allocator.alloc([]u8, rows);
        for (list.items, 0..) |line, row| {
            data[row] = try allocator.alloc(u8, cols);
            for (line, 0..) |c, col| {
                data[row][col] = c;
            }
        }
        return Self{ .data = data, .allocator = allocator };
    }

    pub fn rowCount(self: *Self) usize {
        return self.data.len;
    }

    pub fn colCount(self: *Self) usize {
        return self.data[0].len;
    }

    pub fn deinit(self: *Self) void {
        for (self.data) |line| {
            self.allocator.free(line);
        }
        self.allocator.free(self.data);
    }
};

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

    var buf: [32768]u8 = undefined;
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

pub fn isDigit(c: u8) bool {
    return (c >= '0' and c <= '9');
}

pub fn isSymbol(c: u8) bool {
    return (c < '0' or c > '9') and (c != '.') and (c != '\n');
}

pub fn printMatrix(data: [][]u8) void {
    for (data) |line| {
        for (line) |c| {
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

pub fn toI64(str: []const u8) !i64 {
    return try std.fmt.parseInt(i64, str, 10);
}

pub fn toUsize(str: []const u8) !usize {
    return try std.fmt.parseInt(usize, str, 10);
}

pub fn toU8(str: []const u8) !u8 {
    return try std.fmt.parseInt(u8, str, 10);
}

pub fn hasher(val1: u8, val2: u8) u64 {
    var result = std.hash.Wyhash.init(0);
    result.update(&[_]u8{ val1, val2 });
    return result.final();
}
