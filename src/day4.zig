const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    var myNumbers = std.AutoHashMap(i64, bool).init(allocator);
    defer myNumbers.deinit();

    for (list.items) |line| {
        // print("line={s}\n", .{line});
        var splittedId = mem.split(u8, line, ":");
        if (splittedId.next() == null) {
            break;
        }
        var rest = splittedId.next().?;
        // print("rest={s}\n", .{rest});

        var splittedGroups = mem.split(u8, rest, "|");
        var winningNumberString = splittedGroups.next().?;
        var myNumbersString = splittedGroups.next().?;
        // print("winningNumberString={s}, myNumbersString={s}\n", .{ winningNumberString, myNumbersString });

        myNumbers.clearAndFree();
        var points: i64 = 0;

        var myNumbersStringIndividual = mem.split(u8, myNumbersString, " ");
        while (myNumbersStringIndividual.next()) |entry| {
            if (mem.eql(u8, entry, "")) {
                continue;
            }
            // print("number=[{s}]\n", .{entry});
            const myNumber = try util.toI64(entry);
            try myNumbers.put(myNumber, true);
        }

        var winningNumberStringIndividual = mem.split(u8, winningNumberString, " ");
        while (winningNumberStringIndividual.next()) |entry| {
            if (mem.eql(u8, entry, "")) {
                continue;
            }
            // print("number=[{s}]\n", .{entry});
            const winningNumber = try util.toI64(entry);
            if (myNumbers.get(winningNumber)) |_| {
                // print("match! [{d}]\n", .{winningNumber});
                points = if (points == 0) 1 else points * 2;
            }
        }
        sum += points;
    }
    return sum;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 13);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-4-1.txt");
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
