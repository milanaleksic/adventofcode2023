const std = @import("std");
const math = std.math;
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

    var mapOfVisitedPoints: std.StringHashMap(i64) = std.StringHashMap(i64).init(allocator);
    defer mapOfVisitedPoints.deinit();

    var countOfThreads: usize = 0;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        if (mem.endsWith(u8, entry.key_ptr.*, "A")) {
            var instructionPointer: usize = 0;
            countOfThreads += 1;

            var pointer = entry.key_ptr.*;
            var stepCount: i64 = 0;
            while (stepCount < 1_000_000) {
                stepCount += 1;
                const node = map.get(pointer).?;
                const newPointer = switch (instructions.?[instructionPointer]) {
                    'L' => node.leftId,
                    'R' => node.rightId,
                    else => @panic("can not handle instruction"),
                };
                pointer = newPointer;
                if (mem.endsWith(u8, newPointer, "Z")) {
                    try mapOfVisitedPoints.put(entry.key_ptr.*, stepCount);
                    break;
                }
                instructionPointer = (instructionPointer + 1) % instructions.?.len;
            }
        }
    }

    return lcm(mapOfVisitedPoints);
}

fn lcm(map: std.StringHashMap(i64)) i64 {
    var x: u64 = 0;
    var component = map.valueIterator();
    while (component.next()) |componentRaw| {
        var y: u64 = @bitCast(componentRaw.*);
        if (x == 0) {
            x = y;
        } else {
            // print("LCM of {d} and {d} is ...", .{ x, y });
            x = @divTrunc(x * y, math.gcd(x, y));
            // print("{d}\n", .{x});
        }
    }

    return @bitCast(x);
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 6);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-8-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 10921547990923);
}
