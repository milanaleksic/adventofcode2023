const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Dig = enum {
    Surface,
    Hole,
};

const Ground = struct {
    dig: Dig = Dig.Surface,
    escapes: ?bool = null,
    visited: bool = false,
};

const Coord = struct {
    x: i64,
    y: i64,
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    coords: std.ArrayList(Coord),
    numberOfSteps: i64,

    pub fn initPart1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var coords = std.ArrayList(Coord).init(allocator);
        var coord = Coord{ .x = 0, .y = 0 };
        var numberOfSteps: i64 = 0;
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var sliceIter = std.mem.split(u8, line, " ");
            const command = sliceIter.next().?;
            const amount = try util.toI64(sliceIter.next().?);
            switch (command[0]) {
                'U' => coord.y -= amount,
                'D' => coord.y += amount,
                'L' => coord.x -= amount,
                'R' => coord.x += amount,
                else => undefined,
            }
            numberOfSteps += amount;
            try coords.append(coord);
        }

        // shift all nodes to absolute values for simplicity
        var minX: i64 = 0;
        var minY: i64 = 0;
        for (coords.items) |coordIter| {
            if (coordIter.x < minX) {
                minX = coordIter.x;
            }
            if (coordIter.y < minY) {
                minY = coordIter.y;
            }
        }

        if (minX < 0 or minY < 0) {
            for (coords.items) |*coordFinal| {
                if (minX < 0) {
                    coordFinal.x -= minX;
                }
                if (minY < 0) {
                    coordFinal.y -= minY;
                }
            }
        }

        return Self{
            .allocator = allocator,
            .numberOfSteps = numberOfSteps,
            .coords = coords,
        };
    }

    pub fn initPart2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var coords = std.ArrayList(Coord).init(allocator);
        var coord = Coord{ .x = 0, .y = 0 };
        var numberOfSteps: i64 = 0;
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var sliceIter = std.mem.split(u8, line, " ");
            // ignore first
            _ = sliceIter.next().?;
            // ignore second
            _ = sliceIter.next().?;
            const encodedInstruction = sliceIter.next().?;
            // std.debug.print("Decoding {s}\n", .{encodedInstruction[2..7]});
            const amount = try std.fmt.parseInt(i64, encodedInstruction[2..7], 16);
            switch (encodedInstruction[7]) {
                '3' => coord.y -= amount,
                '1' => coord.y += amount,
                '2' => coord.x -= amount,
                '0' => coord.x += amount,
                else => undefined,
            }
            numberOfSteps += amount;
            try coords.append(coord);
        }

        // shift all nodes to absolute values for simplicity
        var minX: i64 = 0;
        var minY: i64 = 0;
        for (coords.items) |coordIter| {
            if (coordIter.x < minX) {
                minX = coordIter.x;
            }
            if (coordIter.y < minY) {
                minY = coordIter.y;
            }
        }

        if (minX < 0 or minY < 0) {
            for (coords.items) |*coordFinal| {
                if (minX < 0) {
                    coordFinal.x -= minX;
                }
                if (minY < 0) {
                    coordFinal.y -= minY;
                }
            }
        }

        return Self{
            .allocator = allocator,
            .numberOfSteps = numberOfSteps,
            .coords = coords,
        };
    }

    pub fn deinit(self: *Self) void {
        self.coords.deinit();
    }

    pub fn countHoles(self: *Self) i64 {
        // Pick's theorem says: A = i + b/2 - 1, where:
        // A - area behind the polygon
        // b - number of integer points on the polygon
        // i - number of integer points inside the polygon
        //
        // Day 18 asks for (i + b), so we get: i + b = A + b/2 + 1
        // - b is easy (number of steps in the polygon building instructions)
        // - A we can get from https://en.wikipedia.org/wiki/Shoelace_formula
        var doubleA: i64 = 0;
        for (0..self.coords.items.len) |i| {
            const previousY = if (i == 0) self.coords.items.len - 1 else i - 1;
            const nextY = if (i == self.coords.items.len - 1) 0 else i + 1;
            doubleA += self.coords.items[i].x * (self.coords.items[nextY].y - self.coords.items[previousY].y);
        }
        var a = @divTrunc(doubleA, 2);

        return a + @divTrunc(self.numberOfSteps, 2) + 1;
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.initPart1(allocator, list);
    defer data.deinit();

    return data.countHoles();
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 62);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-18.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 52231);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.initPart2(allocator, list);
    defer data.deinit();

    return data.countHoles();
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 952408144115);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-18.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 57196493937398);
}