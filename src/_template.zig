const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    for (list.items) |line| {
        print("line={s}\n", .{line});
    }

    return sum;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 13);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-N-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(data.lines);
    try std.testing.expectEqual(testValue, 27059);
}

pub fn part2(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    for (list.items) |line| {
        print("line={s}\n", .{line});
    }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...
    );
    defer list.deinit();

    const testValue: i64 = try part2(list);
    try std.testing.expectEqual(testValue, 0);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-N-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(data.lines);
    // 1361334 is too low
    try std.testing.expectEqual(testValue, 0);
}
