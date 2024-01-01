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

    rows: std.ArrayList(std.ArrayList(Ground)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var preliminaryList = std.ArrayList(Coord).init(allocator);
        defer preliminaryList.deinit();

        var coord = Coord{ .x = 0, .y = 0 };
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var sliceIter = std.mem.split(u8, line, " ");
            const command = sliceIter.next().?;
            const amount = try util.toUsize(sliceIter.next().?);
            for (0..amount) |_| {
                switch (command[0]) {
                    'U' => coord.y -= 1,
                    'D' => coord.y += 1,
                    'L' => coord.x -= 1,
                    'R' => coord.x += 1,
                    else => undefined,
                }
                try preliminaryList.append(coord);
            }
        }

        // shift all nodes to absolute values for simplicity
        var minX: i64 = 0;
        var minY: i64 = 0;
        var maxX: i64 = 0;
        var maxY: i64 = 0;
        for (preliminaryList.items) |coordIter| {
            if (coordIter.x < minX) {
                minX = coordIter.x;
            }
            if (coordIter.y < minY) {
                minY = coordIter.y;
            }
            if (coordIter.x > maxX) {
                maxX = coordIter.x;
            }
            if (coordIter.y > maxY) {
                maxY = coordIter.y;
            }
        }

        maxX -= minX;
        maxY -= minY;

        var rows = std.ArrayList(std.ArrayList(Ground)).init(allocator);
        for (0..@bitCast(maxY + 1)) |_| {
            var row = std.ArrayList(Ground).init(allocator);
            for (0..@bitCast(maxX + 1)) |_| {
                try row.append(.{});
            }
            try rows.append(row);
        }

        for (preliminaryList.items) |*coordFinal| {
            if (minX < 0) {
                coordFinal.x -= minX;
            }
            if (minY < 0) {
                coordFinal.y -= minY;
            }
            rows.items[@bitCast(coordFinal.y)].items[@bitCast(coordFinal.x)].dig = Dig.Hole;
        }

        return Self{
            .allocator = allocator,
            .rows = rows,
        };
    }

    pub fn checkEscapes(self: *Self, x: usize, y: usize, depth: usize) ?bool {
        const this = &self.rows.items[y].items[x];
        if (this.escapes) |escapes| {
            return escapes;
        }
        if (this.visited or depth == MaxDepth) {
            return this.escapes;
        } else {
            this.visited = true;
        }
        if (this.dig == Dig.Hole) {
            this.escapes = false;
            return false;
        }
        if (x > 0) {
            if (self.checkEscapes(x - 1, y, depth + 1) orelse false) {
                this.escapes = true;
            }
        } else {
            this.escapes = true;
        }
        if (y > 0) {
            if (self.checkEscapes(x, y - 1, depth + 1) orelse false) {
                this.escapes = true;
            }
        } else {
            this.escapes = true;
        }
        if (y < self.rows.items.len - 1) {
            if (self.checkEscapes(x, y + 1, depth + 1) orelse false) {
                this.escapes = true;
            }
        } else {
            this.escapes = true;
        }
        if (x < self.rows.items[0].items.len - 1) {
            if (self.checkEscapes(x + 1, y, depth + 1) orelse false) {
                this.escapes = true;
            }
        } else {
            this.escapes = true;
        }
        return this.escapes;
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
            for (row.items) |n| {
                var ch: u8 = undefined;
                switch (n.dig) {
                    Dig.Surface => {
                        ch = '?';
                        if (n.escapes) |escapesRaw| {
                            ch = if (escapesRaw) ' ' else '#';
                        }
                    },
                    Dig.Hole => ch = '*',
                }
                print("{c}", .{ch});
            }
            print("\n", .{});
        }
    }

    pub fn countHoles(self: *Self) i64 {
        var count: i64 = 0;
        for (self.rows.items) |row| {
            for (row.items) |cell| {
                if ((cell.dig == Dig.Hole) or (cell.escapes == null)) {
                    count += 1;
                }
            }
        }
        return count;
    }
};

const MaxDepth = 255;
const MaxIterations = 20;

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    // data.printMap();

    // loop until solution is found
    var holeCount: i64 = 0;
    for (0..MaxIterations) |iter| {
        for (data.rows.items) |row| {
            for (row.items) |*cell| {
                cell.visited = false;
            }
        }
        for (data.rows.items, 0..) |row, y| {
            for (row.items, 0..) |_, x| {
                if (data.checkEscapes(x, y, 0) orelse false) {
                    data.rows.items[y].items[x].dig = Dig.Surface;
                }
            }
        }
        var newCount = data.countHoles();
        if (newCount == holeCount) {
            std.debug.print("Breaking after {d} loops\n", .{iter});
            break;
        } else {
            holeCount = newCount;
        }
    }

    // data.printMap();

    return holeCount;
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

    // 55507 is too high
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
    var data = try util.openFile(std.testing.allocator, "data/input-18.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
