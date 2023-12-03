const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const allocator = std.heap.page_allocator;

const allowedRed = 12;
const allowedGreen = 13;
const allowedBlue = 14;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    const cols = list.items[0].len;
    const rows = list.items.len;
    var data: [][]u8 = try allocator.alloc([]u8, rows);
    for (list.items, 0..) |line, row| {
        // print("\nline={s}", .{line});
        data[row] = try allocator.alloc(u8, cols);
        for (line, 0..) |c, col| {
            data[row][col] = c;
        }
    }
    defer {
        for (data) |line| {
            allocator.free(line);
        }
        allocator.free(data);
    }

    var x: usize = 0;
    var y: usize = 0;
    while (y < rows) {
        while (x < cols) {
            const c = data[y][x];
            if (isDigit(c)) {
                const beginDigit = x;
                while (isDigit(data[y][x])) {
                    x += 1;
                    if (x == cols) {
                        break;
                    }
                }
                const endDigit = x;
                // print("beginDigit={d}, endDigit={d}\n", .{ beginDigit, endDigit });

                const beginX = if (beginDigit == 0) 0 else beginDigit - 1;
                const endX = if (endDigit >= cols - 1) cols else endDigit + 1;
                const beginY = if (y == 0) y else y - 1;
                const endY = if (y >= rows - 1) rows else y + 2;

                // print("looking between x={d}..{d} and y={d}..{d}\n", .{ beginX, endX, beginY, endY });
                outside: for (beginY..endY) |yi| {
                    for (beginX..endX) |xi| {
                        // print("looking at x={d} y={d}, data={c}\n", .{ xi, yi, data[yi][xi] });
                        if (isSymbol(data[yi][xi])) {
                            // print("parsing '{s}'\n", .{data[y][beginDigit..endDigit]});
                            const number = try parseInt(i64, data[y][beginDigit..endDigit], 10);
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

fn isDigit(c: u8) bool {
    return (c >= '0' and c <= '9');
}

fn isSymbol(c: u8) bool {
    return (c < '0' or c > '9') and (c != '.') and (c != '\n');
}

fn printMatrix(data: [][]u8) void {
    for (data) |line| {
        for (line) |c| {
            print("{c}", .{c});
        }
        print("\n", .{});
    }
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

    const cols = list.items[0].len;
    const rows = list.items.len;
    var data: [][]u8 = try allocator.alloc([]u8, rows);
    for (list.items, 0..) |line, row| {
        // print("\nline={s}", .{line});
        data[row] = try allocator.alloc(u8, cols);
        for (line, 0..) |c, col| {
            data[row][col] = c;
        }
    }
    defer {
        for (data) |line| {
            allocator.free(line);
        }
        allocator.free(data);
    }

    var x: usize = 0;
    var y: usize = 0;
    while (y < rows) {
        while (x < cols) {
            const c = data[y][x];
            if (isDigit(c)) {
                const beginDigit = x;
                while (isDigit(data[y][x])) {
                    x += 1;
                    if (x == cols) {
                        break;
                    }
                }
                const endDigit = x;

                const beginX = if (beginDigit == 0) 0 else beginDigit - 1;
                const endX = if (endDigit >= cols - 1) cols else endDigit + 1;
                const beginY = if (y == 0) y else y - 1;
                const endY = if (y >= rows - 1) rows else y + 2;

                for (beginY..endY) |yi| {
                    for (beginX..endX) |xi| {
                        if (isGear(data[yi][xi])) {
                            const number = try parseInt(i64, data[y][beginDigit..endDigit], 10);
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

test "part 2 test" {
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
