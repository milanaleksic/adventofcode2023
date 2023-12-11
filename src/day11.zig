const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

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

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    rows: std.ArrayList(std.ArrayList(NodeType)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rows: std.ArrayList(std.ArrayList(NodeType)) = try std.ArrayList(std.ArrayList(NodeType)).initCapacity(allocator, list.items.len);
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var row: std.ArrayList(NodeType) = try std.ArrayList(NodeType).initCapacity(allocator, line.len);
            var numberOfGalaxiesInRow: usize = 0;
            for (line) |char| {
                const nodeType = NodeType.fromChar(char);
                if (nodeType == NodeType.Galaxy) {
                    numberOfGalaxiesInRow += 1;
                }
                try row.append(nodeType);
            }
            if (numberOfGalaxiesInRow == 0) {
                var emptyRow: std.ArrayList(NodeType) = try std.ArrayList(NodeType).initCapacity(allocator, line.len);
                for (line) |_| {
                    try emptyRow.append(NodeType.Space);
                }
                try rows.append(emptyRow);
            }
            try rows.append(row);
        }
        var x: usize = 0;
        while (x < rows.items[0].items.len) {
            var hasGalaxyInColumn = false;
            for (rows.items) |row| {
                if (row.items[x] == NodeType.Galaxy) {
                    hasGalaxyInColumn = true;
                    break;
                }
            }
            if (!hasGalaxyInColumn) {
                for (rows.items) |*row| {
                    try row.insert(x, NodeType.Space);
                }
                x += 1;
            }
            x += 1;
        }
        return Self{
            .rows = rows,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |row| {
            row.deinit();
        }
        self.rows.deinit();
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
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    data.printMap();

    // access input data...
    // for (data.rows.items) |rowData| {

    // }

    return sum;
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

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, -1);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-11-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
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
    var data = try util.openFile(std.testing.allocator, "data/input-11-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
