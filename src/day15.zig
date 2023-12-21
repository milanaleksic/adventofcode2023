const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    instructions: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var instructions: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
        for (list.items) |line| {
            var iter = std.mem.split(u8, line, ",");
            while (iter.next()) |split| {
                try instructions.append(split);
            }
        }
        return Self{
            .instructions = instructions,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.instructions.deinit();
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.instructions.items) |instr| {
        var cur: i64 = 0;
        for (instr) |ch| {
            cur += ch;
            cur *= 17;
            cur = @mod(cur, 256);
            // std.debug.print("cur={d}\n", .{cur});
        }
        sum += cur;
    }

    return sum;
}

test "part 1 test 0" {
    var list = try util.parseToListOfStrings([]const u8,
        \\HASH
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 52);
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 1320);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-15.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 506869);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    // access input data...
    // for (data.rows.items) |rowData| {

    // }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, -1);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-15.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
