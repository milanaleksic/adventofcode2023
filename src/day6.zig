const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var product: i64 = 1;
    var timesRaw = list.items[0];
    var distanceRaw = list.items[1];

    var times: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);
    defer times.deinit();

    var distances: std.ArrayList(i64) = std.ArrayList(i64).init(allocator);
    defer distances.deinit();

    var timeIter = mem.split(u8, timesRaw, " ");
    while (timeIter.next()) |timeIndividualRaw| {
        var time = util.toI64(timeIndividualRaw) catch -1;
        if (time == -1) {
            continue;
        }
        try times.append(time);
    }

    var distanceIter = mem.split(u8, distanceRaw, " ");
    while (distanceIter.next()) |distanceIndividualRaw| {
        var distance = util.toI64(distanceIndividualRaw) catch -1;
        if (distance == -1) {
            continue;
        }
        try distances.append(distance);
    }

    for (times.items, 0..) |time, index| {
        var currentRecord = distances.items[index];
        // print("Looking at {d}/{d}\n", .{ time, currentRecord });

        var numberOfBetterTimes: i64 = 0;
        for (0..@bitCast(time)) |buttonHoldPeriod| {
            const buttonHoldPeriodI64: i64 = @bitCast(buttonHoldPeriod);
            const remainingTime = time - buttonHoldPeriodI64;
            const speed = buttonHoldPeriodI64;
            const distanceTraveled = speed * remainingTime;
            if (distanceTraveled > currentRecord) {
                numberOfBetterTimes += 1;
            }
        }
        // print("number of better times: {d}\n", .{numberOfBetterTimes});
        product *= numberOfBetterTimes;
    }

    return product;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\Time:      7  15   30
        \\Distance:  9  40  200
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 288);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-6.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 275724);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var timesRaw = list.items[0];
    var distanceRaw = list.items[1];

    var oneTimeString: []const u8 = "";
    defer allocator.free(oneTimeString);

    var timeIter = mem.split(u8, timesRaw, " ");
    while (timeIter.next()) |timeIndividualRaw| {
        var time = util.toI64(timeIndividualRaw) catch -1;
        if (time == -1) {
            continue;
        }
        var newOneTimeString = try std.fmt.allocPrint(allocator, "{s}{s}", .{ oneTimeString, timeIndividualRaw });
        allocator.free(oneTimeString);
        oneTimeString = newOneTimeString;
    }
    var oneTime: i64 = try util.toI64(oneTimeString);

    var oneDistanceString: []const u8 = "";
    defer allocator.free(oneDistanceString);

    var distanceIter = mem.split(u8, distanceRaw, " ");
    while (distanceIter.next()) |distanceIndividualRaw| {
        var time = util.toI64(distanceIndividualRaw) catch -1;
        if (time == -1) {
            continue;
        }
        var newOneDistanceString = try std.fmt.allocPrint(allocator, "{s}{s}", .{ oneDistanceString, distanceIndividualRaw });
        allocator.free(oneDistanceString);
        oneDistanceString = newOneDistanceString;
    }
    var currentRecord: i64 = try util.toI64(oneDistanceString);

    // print("Looking at {d}/{d}\n", .{ oneTime, currentRecord });

    var numberOfBetterTimes: i64 = 0;
    for (0..@bitCast(oneTime)) |buttonHoldPeriod| {
        const buttonHoldPeriodI64: i64 = @bitCast(buttonHoldPeriod);
        const remainingTime = oneTime - buttonHoldPeriodI64;
        const speed = buttonHoldPeriodI64;
        const distanceTraveled = speed * remainingTime;
        if (distanceTraveled > currentRecord) {
            numberOfBetterTimes += 1;
        }
    }
    // print("number of better times: {d}\n", .{numberOfBetterTimes});
    return numberOfBetterTimes;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\Time:      7  15   30
        \\Distance:  9  40  200
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 71503);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-6.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 37286485);
}
