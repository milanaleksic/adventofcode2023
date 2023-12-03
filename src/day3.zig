const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    var matrix = try util.InputMatrix.init(allocator, list);
    defer matrix.deinit();
    var data = matrix.data;

    var x: usize = 0;
    var y: usize = 0;
    while (y < matrix.rowCount()) {
        while (x < matrix.colCount()) {
            const c = data[y][x];
            if (util.isDigit(c)) {
                const beginDigit = x;
                while (util.isDigit(data[y][x])) {
                    x += 1;
                    if (x == matrix.colCount()) {
                        break;
                    }
                }
                const endDigit = x;
                // print("beginDigit={d}, endDigit={d}\n", .{ beginDigit, endDigit });

                const beginX = if (beginDigit == 0) 0 else beginDigit - 1;
                const endX = if (endDigit >= matrix.colCount() - 1) matrix.colCount() else endDigit + 1;
                const beginY = if (y == 0) y else y - 1;
                const endY = if (y >= matrix.rowCount() - 1) matrix.rowCount() else y + 2;

                // print("looking between x={d}..{d} and y={d}..{d}\n", .{ beginX, endX, beginY, endY });
                outside: for (beginY..endY) |yi| {
                    for (beginX..endX) |xi| {
                        // print("looking at x={d} y={d}, data={c}\n", .{ xi, yi, data[yi][xi] });
                        if (util.isSymbol(data[yi][xi])) {
                            // print("parsing '{s}'\n", .{data[y][beginDigit..endDigit]});
                            const number = try util.toI64(data[y][beginDigit..endDigit]);
                            // print("{d}\n", .{number});
                            sum += number;
                            break :outside;
                        }
                    }
                }
            }
            x += 1;
        }
        y += 1;
        x = 0;
    }

    return sum;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 4361);
}

test "part 1 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\467..114..
        \\...*......
        \\..35-.633.
        \\..18..-...
        \\617*......
        \\.....+.58.
        \\.-592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 4379);
}

test "part 1 test 3" {
    var list = try util.parseToListOfStrings([]const u8,
        \\..........
        \\.......-..
        \\...123....
        \\..........
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 0);
}

test "part 1 test 4" {
    var list = try util.parseToListOfStrings([]const u8,
        \\..........
        \\......-...
        \\...123....
        \\..........
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 123);
}

test "part 1 test 5" {
    var list = try util.parseToListOfStrings([]const u8,
        \\..........
        \\..........
        \\...123....
        \\......-...
        \\..........
        \\..........
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 123);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-3-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(data.lines);
    // 513328 is too low
    // 516161 is too high
    try std.testing.expectEqual(testValue, 514969);
}

const Part = struct {
    count: i64,
    product: i64,
};

pub fn part2(list: std.ArrayList([]const u8)) !i64 {
    var mapOfNumbersByGearCoordinate = std.AutoHashMap([2]usize, Part).init(allocator);
    defer mapOfNumbersByGearCoordinate.deinit();

    var matrix = try util.InputMatrix.init(allocator, list);
    defer matrix.deinit();
    var data = matrix.data;

    var x: usize = 0;
    var y: usize = 0;
    while (y < matrix.rowCount()) {
        while (x < matrix.colCount()) {
            const c = data[y][x];
            if (util.isDigit(c)) {
                const beginDigit = x;
                while (util.isDigit(data[y][x])) {
                    x += 1;
                    if (x == matrix.colCount()) {
                        break;
                    }
                }
                const endDigit = x;

                const beginX = if (beginDigit == 0) 0 else beginDigit - 1;
                const endX = if (endDigit >= matrix.colCount() - 1) matrix.colCount() else endDigit + 1;
                const beginY = if (y == 0) y else y - 1;
                const endY = if (y >= matrix.rowCount() - 1) matrix.rowCount() else y + 2;

                for (beginY..endY) |yi| {
                    for (beginX..endX) |xi| {
                        if (isGear(data[yi][xi])) {
                            const number = try util.toI64(data[y][beginDigit..endDigit]);
                            const key = [2]usize{ yi, xi };
                            var existingOptional: ?Part = mapOfNumbersByGearCoordinate.get(key);
                            if (existingOptional) |existing| {
                                try mapOfNumbersByGearCoordinate.put(key, .{
                                    .count = existing.count + 1,
                                    .product = if (existing.count == 1) existing.product * number else 0,
                                });
                                // print("adding '{d}'\n", .{number});
                            } else {
                                try mapOfNumbersByGearCoordinate.put(key, .{
                                    .count = 1,
                                    .product = number,
                                });
                                // print("storing '{d}'\n", .{number});
                            }
                            // print("parsing '{s}'\n", .{data[y][beginDigit..endDigit]});
                            // print("{d}\n", .{number});
                        }
                    }
                }
            }
            x += 1;
        }
        y += 1;
        x = 0;
    }

    var sum: i64 = 0;
    var iterator = mapOfNumbersByGearCoordinate.iterator();
    while (iterator.next()) |entry| {
        // print("entry {}/{} has {d} numbers\n", .{ entry.key_ptr.*[0], entry.key_ptr.*[1], entry.value_ptr.*.len });
        if (entry.value_ptr.*.count == 2) {
            sum += entry.value_ptr.*.product;
        }
    }

    return sum;
}

fn isGear(c: u8) bool {
    return c == '*';
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    defer list.deinit();

    const testValue: i64 = try part2(list);
    try std.testing.expectEqual(testValue, 467835);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-3-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(data.lines);
    try std.testing.expectEqual(testValue, 78915902);
}
