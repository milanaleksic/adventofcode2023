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

pub fn part2(list: std.ArrayList([]const u8)) !i64 {
    var myNumbers = std.AutoHashMap(i64, bool).init(allocator);
    defer myNumbers.deinit();
    var myCards = std.AutoHashMap(i64, i64).init(allocator);
    defer myCards.deinit();

    for (0..list.items.len) |i| {
        try myCards.put(@bitCast(i), 1);
    }

    for (list.items, 0..) |line, index| {
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

        var myNumbersStringIndividual = mem.split(u8, myNumbersString, " ");
        while (myNumbersStringIndividual.next()) |entry| {
            if (mem.eql(u8, entry, "")) {
                continue;
            }
            // print("number=[{s}]\n", .{entry});
            const myNumber = try util.toI64(entry);
            try myNumbers.put(myNumber, true);
        }

        var numberOfWinning: usize = 0;
        var winningNumberStringIndividual = mem.split(u8, winningNumberString, " ");
        while (winningNumberStringIndividual.next()) |entry| {
            if (mem.eql(u8, entry, "")) {
                continue;
            }
            // print("number=[{s}]\n", .{entry});
            const winningNumber = try util.toI64(entry);
            if (myNumbers.get(winningNumber)) |_| {
                // print("match! [{d}]\n", .{winningNumber});
                numberOfWinning += 1;
            }
        }

        for (0..numberOfWinning) |offset| {
            const indexI64: i64 = @bitCast(index);
            const offsetI64: i64 = @bitCast(offset);
            const cardIndex: i64 = indexI64 + offsetI64 + 1;
            const countOfThisCard = myCards.get(indexI64).?;
            const countOfOffsetCard = myCards.get(cardIndex).?;
            // print("countOfThisCard({d})={d}, countOfOffsetCard({d})={d}\n", .{ indexI64, countOfThisCard, offsetI64, countOfOffsetCard });
            try myCards.put(cardIndex, countOfOffsetCard + countOfThisCard);
        }
    }
    var sum: i64 = 0;
    var iter = myCards.iterator();
    while (iter.next()) |entry| {
        sum += entry.value_ptr.*;
    }
    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    );
    defer list.deinit();

    const testValue: i64 = try part2(list);
    try std.testing.expectEqual(testValue, 30);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-4-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(data.lines);
    // 1361334 is too low
    try std.testing.expectEqual(testValue, 5744979);
}
