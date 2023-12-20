const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const NodeType = enum {
    Empty,
    RoundRock,
    CubeRock,
};

const Node = struct {
    const Self = @This();
    nodeType: NodeType,

    pub fn toString(self: *Self) []const u8 {
        return switch (self.nodeType) {
            NodeType.Empty => " ",
            NodeType.RoundRock => "O",
            NodeType.CubeRock => "#",
        };
    }
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    rows: std.ArrayList(std.ArrayList(Node)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rows: std.ArrayList(std.ArrayList(Node)) = std.ArrayList(std.ArrayList(Node)).init(allocator);
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var row: std.ArrayList(Node) = std.ArrayList(Node).init(allocator);
            for (line) |c| {
                const nodeType: NodeType = switch (c) {
                    '#' => NodeType.CubeRock,
                    'O' => NodeType.RoundRock,
                    '.' => NodeType.Empty,
                    else => @panic("incompatible input detected"),
                };
                try row.append(Node{
                    .nodeType = nodeType,
                });
            }
            try rows.append(row);
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
        for (0..self.rows.items[0].items.len) |_| {
            print("*", .{});
        }
        print("\n", .{});
        for (self.rows.items) |row| {
            for (row.items) |*node| {
                print("{s}", .{node.toString()});
            }
            print("\n", .{});
        }
    }

    pub fn moveToNorth(self: *Self) void {
        for (0..self.rows.items.len) |x| {
            var foundation: usize = 0;
            for (0..self.rows.items.len) |y| {
                var cell = self.rows.items[y].items[x];
                switch (cell.nodeType) {
                    NodeType.CubeRock => foundation = y + 1,
                    NodeType.RoundRock => {
                        if (foundation < y) {
                            // print("Moving item from {d} to {d}\n", .{ y, foundation });
                            self.rows.items[foundation].items[x].nodeType = NodeType.RoundRock;
                            self.rows.items[y].items[x].nodeType = NodeType.Empty;
                        }
                        foundation += 1;
                    },
                    else => {},
                }
            }
        }
    }

    // pub fn moveToSouth(self: *Self) void {
    //     for (0..self.rows.items.len) |x| {
    //         var foundation: usize = self.rows.items.len - 1;
    //         for (self.rows.items, 0..) |*row, y| {
    //             var cell = row.items[x];
    //             switch (cell.nodeType) {
    //                 NodeType.CubeRock => foundation = y + 1,
    //                 NodeType.RoundRock => {
    //                     if (foundation < y) {
    //                         // print("Moving item from {d} to {d}\n", .{ y, foundation });
    //                         self.rows.items[foundation].items[x].nodeType = NodeType.RoundRock;
    //                         self.rows.items[y].items[x].nodeType = NodeType.Empty;
    //                     }
    //                     foundation += 1;
    //                 },
    //                 else => {},
    //             }
    //         }
    //     }
    // }

    pub fn calculate(self: *Self) usize {
        var sum: usize = 0;
        const colSize = self.rows.items.len;
        for (self.rows.items, 0..) |row, y| {
            for (row.items) |node| {
                switch (node.nodeType) {
                    NodeType.RoundRock => {
                        sum += colSize - y;
                    },
                    else => {},
                }
            }
        }
        return sum;
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    // data.printMap();

    data.moveToNorth();

    // data.printMap();

    return data.calculate();
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 136);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-14.txt");
    defer data.deinit();

    const testValue: usize = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 113456);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (0..100) |_| {
        data.moveToNorth();
        // data.moveToWest();
        // data.moveToSouth();
        // data.moveToEast();
        print("{d}\n", .{data.calculate()});
    }

    return data.calculate();
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 64);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-14.txt");
    defer data.deinit();

    const testValue: usize = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 0);
}
