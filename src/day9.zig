const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    rows: std.ArrayList(std.ArrayList(i64)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rows: std.ArrayList(std.ArrayList(i64)) = std.ArrayList(std.ArrayList(i64)).init(allocator);
        for (list.items) |line| {
            var row: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);
            var lineIter = std.mem.split(u8, line, " ");
            while (lineIter.next()) |number| {
                if (number.len == 0) {
                    continue;
                }
                try row.append(try util.toI64(number));
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
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.rows.items) |rowData| {
        var pyramid: std.ArrayList(std.ArrayList(i64)) = std.ArrayList(std.ArrayList(i64)).init(allocator);
        defer {
            for (pyramid.items) |row| {
                row.deinit();
            }
            pyramid.deinit();
        }

        try pyramid.append(try rowData.clone());

        // printPyramid(pyramid);

        // calculate lower rows
        var index: usize = 0;
        while (true) {
            var newRow: std.ArrayList(i64) = try std.ArrayList(i64).initCapacity(allocator, rowData.items.len - index);
            var previous: ?i64 = null;
            var allZeros: bool = true;
            for (pyramid.items[pyramid.items.len - 1].items) |n| {
                if (previous) |prevRaw| {
                    var newN = n - prevRaw;
                    if (newN != 0) {
                        allZeros = false;
                    }
                    try newRow.append(newN);
                    previous = n;
                } else {
                    previous = n;
                }
            }
            try pyramid.append(newRow);
            if (allZeros) {
                break;
            }
            index += 1;
        }
        // printPyramid(pyramid);

        // forecast
        for (1..(pyramid.items.len)) |i| {
            var r = &pyramid.items[pyramid.items.len - i];
            var prevR = &pyramid.items[pyramid.items.len - i - 1];
            var forecasted = r.items[r.items.len - 1] + prevR.items[prevR.items.len - 1];
            try prevR.append(forecasted);
            // print("forecasting {d} for row {d}\n", .{ forecasted, pyramid.items.len - i - 1 });
        }
        // printPyramid(pyramid);

        sum += pyramid.items[0].items[pyramid.items[0].items.len - 1];
    }

    return sum;
}

fn printPyramid(pyramid: std.ArrayList(std.ArrayList(i64))) void {
    for (pyramid.items) |row| {
        for (row.items) |number| {
            print("{d} ", .{number});
        }
        print("\n", .{});
    }
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 114);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-9-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 1647269739);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.rows.items) |rowData| {
        var pyramid: std.ArrayList(std.ArrayList(i64)) = std.ArrayList(std.ArrayList(i64)).init(allocator);
        defer {
            for (pyramid.items) |row| {
                row.deinit();
            }
            pyramid.deinit();
        }

        try pyramid.append(try rowData.clone());

        // calculate lower rows
        var index: usize = 0;
        while (true) {
            var newRow: std.ArrayList(i64) = try std.ArrayList(i64).initCapacity(allocator, rowData.items.len - index);
            var previous: ?i64 = null;
            var allZeros: bool = true;
            for (pyramid.items[pyramid.items.len - 1].items) |n| {
                if (previous) |prevRaw| {
                    var newN = n - prevRaw;
                    if (newN != 0) {
                        allZeros = false;
                    }
                    try newRow.append(newN);
                    previous = n;
                } else {
                    previous = n;
                }
            }
            try pyramid.append(newRow);
            if (allZeros) {
                break;
            }
            index += 1;
        }
        // printPyramid(pyramid);

        // forecast
        for (1..(pyramid.items.len)) |i| {
            var r = &pyramid.items[pyramid.items.len - i];
            var prevR = &pyramid.items[pyramid.items.len - i - 1];
            var forecasted = prevR.items[0] - r.items[0];
            try prevR.insert(0, forecasted);
            // print("forecasting {d} for row {d}\n", .{ forecasted, pyramid.items.len - i - 1 });
        }
        // printPyramid(pyramid);

        sum += pyramid.items[0].items[0];
    }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 2);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-9-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 864);
}
