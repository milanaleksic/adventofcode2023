const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Node = struct {
    leftId: []const u8,
    rightId: []const u8,
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var instructions: ?[]const u8 = null;
    defer {
        if (instructions) |instructionsRaw| {
            allocator.free(instructionsRaw);
        }
    }

    var map: std.StringHashMap(Node) = std.StringHashMap(Node).init(allocator);
    defer map.deinit();

    for (list.items) |line| {
        // print("line={s}\n", .{line});
        if (line.len == 0) {
            continue;
        }
        if (instructions == null) {
            instructions = try allocator.dupe(u8, line);
        } else {
            var splitIter = mem.split(u8, line, "=");
            const id = mem.trim(u8, splitIter.next().?, " ");
            const coordinates = mem.trim(u8, splitIter.next().?, " ");
            try map.put(id, .{
                .leftId = coordinates[1..4],
                .rightId = coordinates[6..9],
            });
        }
    }

    // print("instructions=[{s}]\n", .{instructions.?});
    // var mapIter = map.iterator();
    // while (mapIter.next()) |entry| {
    //     print("[{s}] -> [{s}]/[{s}]\n", .{ entry.key_ptr.*, entry.value_ptr.*.leftId, entry.value_ptr.*.rightId });
    // }

    var instructionPointer: usize = 0;
    var pointer: []const u8 = "AAA";
    var stepCount: i64 = 0;
    while (stepCount < 1000000) {
        stepCount += 1;

        const node = map.get(pointer).?;
        switch (instructions.?[instructionPointer]) {
            'L' => pointer = node.leftId,
            'R' => pointer = node.rightId,
            else => @panic("can not handle instruction"),
        }
        instructionPointer = (instructionPointer + 1) % instructions.?.len;
        if (mem.eql(u8, pointer, "ZZZ")) {
            break;
        }
    }

    return stepCount;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 6);
}

test "part 1 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 2);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-8-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 14429);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    _ = allocator;
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

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 0);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-8-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 0);
}
