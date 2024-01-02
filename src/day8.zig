const std = @import("std");
const math = std.math;
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

// Note: for this one I had to reach out for help since I detected a cycle
// but couldn't figure out the methodology to do something with it (LCM)

const Node = struct {
    leftId: []const u8,
    rightId: []const u8,
};

const Data = struct {
    const Self = @This();
    instructions: []const u8,
    map: std.StringHashMap(Node),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var instructions: ?[]const u8 = null;
        var map: std.StringHashMap(Node) = std.StringHashMap(Node).init(allocator);
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
        return Self{
            .instructions = instructions.?,
            .map = map,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.instructions);
        self.map.deinit();
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.init(allocator, list);
    defer data.deinit();

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

        const node = data.map.get(pointer).?;
        switch (data.instructions[instructionPointer]) {
            'L' => pointer = node.leftId,
            'R' => pointer = node.rightId,
            else => @panic("can not handle instruction"),
        }
        instructionPointer = (instructionPointer + 1) % data.instructions.len;
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
    var data = try util.openFile(std.testing.allocator, "data/input-8.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 14429);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    var mapOfVisitedPoints: std.StringHashMap(i64) = std.StringHashMap(i64).init(allocator);
    defer mapOfVisitedPoints.deinit();

    var iter = data.map.iterator();
    while (iter.next()) |entry| {
        if (mem.endsWith(u8, entry.key_ptr.*, "A")) {
            const start = entry.key_ptr.*;
            var instructionPointer: usize = 0;
            var pointer = start;
            var stepCount: i64 = 0;
            while (stepCount < 1_000_000) {
                stepCount += 1;
                const node = data.map.get(pointer).?;
                const newPointer = switch (data.instructions[instructionPointer]) {
                    'L' => node.leftId,
                    'R' => node.rightId,
                    else => @panic("can not handle instruction"),
                };
                pointer = newPointer;
                if (mem.endsWith(u8, newPointer, "Z")) {
                    try mapOfVisitedPoints.put(start, stepCount);
                    break;
                }
                instructionPointer = (instructionPointer + 1) % data.instructions.len;
            }
        }
    }

    // if one does a cycle analysis, you will notice that the nodes are going in circles
    // and the distance between the start and the first occurrence of Z is equal between
    // the step when cycle begins and cycle ends, therefore we get a Z on each cycle length
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

test "part 2 cycle analysis" {
    var input = try util.openFile(std.testing.allocator, "data/input-8.txt");
    defer input.deinit();

    var data = try Data.init(std.testing.allocator, input.lines);
    defer data.deinit();

    var iter = data.map.iterator();
    while (iter.next()) |entry| {
        if (mem.endsWith(u8, entry.key_ptr.*, "A")) {
            try std.testing.expect(try cycleAnalysis(data.map, entry.key_ptr.*, data.instructions));
        }
    }
}

fn cycleAnalysis(map: std.StringHashMap(Node), start: []const u8, instructions: []const u8) !bool {
    var mapCycleDetection: std.StringHashMap(usize) = std.StringHashMap(usize).init(std.testing.allocator);
    defer {
        var keyIter = mapCycleDetection.keyIterator();
        while (keyIter.next()) |k| {
            std.testing.allocator.free(k.*);
        }
        mapCycleDetection.deinit();
    }

    var stepOfEnding: usize = 0;
    var stepOfCycleStart: usize = 0;
    var stepOfCycleEnd: usize = 0;

    var instructionPointer: usize = 0;
    var pointer = start;
    var stepCount: usize = 0;
    while (stepCount < 1_000_000) {
        stepCount += 1;
        const node = map.get(pointer).?;
        const newPointer = switch (instructions[instructionPointer]) {
            'L' => node.leftId,
            'R' => node.rightId,
            else => @panic("can not handle instruction"),
        };
        pointer = newPointer;
        if (mem.endsWith(u8, newPointer, "Z")) {
            stepOfEnding = stepCount;
            // print("ending detected, stepOfEnding={d}\n", .{stepOfEnding});
        }

        const key = try std.fmt.allocPrint(std.testing.allocator, "{s}{d}", .{ pointer, instructionPointer });
        if (mapCycleDetection.get(key)) |existing| {
            // print("cycle detected at {d}, lengthOfCycle={d}\n", .{ stepCount, stepCount - existing });
            stepOfCycleStart = existing;
            stepOfCycleEnd = stepCount;
            std.testing.allocator.free(key);
            break;
        } else {
            try mapCycleDetection.put(key, stepCount);
        }
        instructionPointer = (instructionPointer + 1) % instructions.len;
    }
    // print("stepOfEnding={d} stepOfCycleStart={d}, stepOfCycleEnd={d}\n", .{ stepOfEnding, stepOfCycleStart, stepOfCycleEnd });
    return stepOfEnding == stepOfCycleEnd - stepOfCycleStart;
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-8.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 10921547990923);
}
