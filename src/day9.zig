const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    for (list.items) |line| {
        // print("line={s}\n", .{line});

        var pyramid: std.ArrayList(std.ArrayList(i64)) = std.ArrayList(std.ArrayList(i64)).init(allocator);
        defer {
            for (pyramid.items) |row| {
                row.deinit();
            }
            pyramid.deinit();
        }

        var row: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);

        // convert to pyramid
        var lineIter = std.mem.split(u8, line, " ");
        while (lineIter.next()) |number| {
            if (number.len == 0) {
                continue;
            }
            try row.append(try util.toI64(number));
        }
        try pyramid.append(row);

        // printPyramid(pyramid);

        // calculate lower rows
        while (true) {
            var newRow: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);
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

    for (list.items) |line| {
        // print("line={s}\n", .{line});

        var pyramid: std.ArrayList(std.ArrayList(i64)) = std.ArrayList(std.ArrayList(i64)).init(allocator);
        defer {
            for (pyramid.items) |row| {
                row.deinit();
            }
            pyramid.deinit();
        }

        var row: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);

        // convert to pyramid
        var lineIter = std.mem.split(u8, line, " ");
        while (lineIter.next()) |number| {
            if (number.len == 0) {
                continue;
            }
            try row.append(try util.toI64(number));
        }
        try pyramid.append(row);

        // printPyramid(pyramid);

        // calculate lower rows
        while (true) {
            var newRow: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);
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
