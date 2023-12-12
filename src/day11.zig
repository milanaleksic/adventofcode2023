const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const math = std.math;

const NodeType = enum {
    Space,
    Galaxy,

    pub fn fromChar(x: u8) NodeType {
        return switch (x) {
            '#' => NodeType.Galaxy,
            '.' => NodeType.Space,
            else => unreachable,
        };
    }
};

const Location = struct {
    id: usize,
    x: usize,
    y: usize,
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    galaxies: std.ArrayList(Location),
    rows: std.ArrayList(std.ArrayList(NodeType)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rows: std.ArrayList(std.ArrayList(NodeType)) = try std.ArrayList(std.ArrayList(NodeType)).initCapacity(allocator, list.items.len);
        var countOfGalaxies: usize = 0;
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var row: std.ArrayList(NodeType) = try std.ArrayList(NodeType).initCapacity(allocator, line.len);
            for (line) |char| {
                const nodeType = NodeType.fromChar(char);
                if (nodeType == NodeType.Galaxy) {
                    countOfGalaxies += 1;
                }
                try row.append(nodeType);
            }
            try rows.append(row);
        }

        var id: usize = 1;
        var galaxies: std.ArrayList(Location) = try std.ArrayList(Location).initCapacity(allocator, countOfGalaxies);
        for (rows.items, 0..) |rowData, yi| {
            for (rowData.items, 0..) |cell, xi| {
                if (cell == NodeType.Galaxy) {
                    try galaxies.append(Location{
                        .x = xi,
                        .y = yi,
                        .id = id,
                    });
                    id += 1;
                }
            }
        }

        return Self{
            .rows = rows,
            .allocator = allocator,
            .galaxies = galaxies,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |row| {
            row.deinit();
        }
        self.rows.deinit();
        self.galaxies.deinit();
    }

    pub fn printMap(self: *Self) void {
        print("\n", .{});
        for (self.rows.items) |row| {
            for (row.items) |cell| {
                switch (cell) {
                    NodeType.Galaxy => print("#", .{}),
                    NodeType.Space => print(".", .{}),
                }
            }
            print("\n", .{});
        }
    }

    pub fn moveEmptyFor(self: *Self, value: usize) void {
        // add rows
        var y: usize = self.rows.items.len;
        while (y > 0) {
            y -= 1;
            var hasGalaxies = false;
            for (self.rows.items[y].items) |cell| {
                if (cell == NodeType.Galaxy) {
                    hasGalaxies = true;
                    break;
                }
            }
            if (!hasGalaxies) {
                for (self.galaxies.items) |*galaxy| {
                    if (galaxy.y > y) {
                        galaxy.y += value;
                    }
                }
            }
        }

        // add columns
        var x: usize = self.rows.items[0].items.len;
        while (x > 0) {
            x -= 1;
            var hasGalaxyInColumn = false;
            for (self.rows.items) |row| {
                if (row.items[x] == NodeType.Galaxy) {
                    hasGalaxyInColumn = true;
                    break;
                }
            }
            if (!hasGalaxyInColumn) {
                for (self.galaxies.items) |*galaxy| {
                    if (galaxy.x > x) {
                        galaxy.x += value;
                    }
                }
            }
        }
    }
};

fn manhattan(loc1: Location, loc2: Location) usize {
    var loc1x: i64 = @bitCast(loc1.x);
    var loc1y: i64 = @bitCast(loc1.y);
    var loc2x: i64 = @bitCast(loc2.x);
    var loc2y: i64 = @bitCast(loc2.y);
    return math.absCast(loc1x - loc2x) + math.absCast(loc1y - loc2y);
}

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var sum: usize = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    data.moveEmptyFor(1);

    for (data.galaxies.items) |galaxy1| {
        for (data.galaxies.items) |galaxy2| {
            if (galaxy1.x == galaxy2.x and galaxy1.y == galaxy2.y) {
                continue;
            }
            sum += manhattan(galaxy1, galaxy2);
        }
    }

    return @divTrunc(sum, 2);
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 374);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-11-1.txt");
    defer data.deinit();

    const testValue: usize = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 9599070);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    return moveAndCalculate(&data, 1_000_000 - 1);
}

fn moveAndCalculate(data: *Data, offset: usize) usize {
    var sum: usize = 0;
    data.moveEmptyFor(offset);

    for (data.galaxies.items) |galaxy1| {
        for (data.galaxies.items) |galaxy2| {
            if (galaxy1.x == galaxy2.x and galaxy1.y == galaxy2.y) {
                continue;
            }
            sum += manhattan(galaxy1, galaxy2);
        }
    }

    return @divTrunc(sum, 2);
}

test "part 2 test 0" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    );
    defer list.deinit();

    var data = try Data.init(std.testing.allocator, list);
    defer data.deinit();

    const testValue: usize = moveAndCalculate(&data, 2);
    try std.testing.expectEqual(testValue, 1030);
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    );
    defer list.deinit();

    var data = try Data.init(std.testing.allocator, list);
    defer data.deinit();

    const testValue: usize = moveAndCalculate(&data, 9);
    try std.testing.expectEqual(testValue, 1030);
}

test "part 2 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    );
    defer list.deinit();

    var data = try Data.init(std.testing.allocator, list);
    defer data.deinit();

    const testValue: usize = moveAndCalculate(&data, 99);
    try std.testing.expectEqual(testValue, 8410);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-11-1.txt");
    defer data.deinit();

    const testValue: usize = try part2(std.testing.allocator, data.lines);
    // 842646756432 is too high
    try std.testing.expectEqual(testValue, 842645913794);
}
