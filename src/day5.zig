const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var mapping = std.AutoHashMap(i64, i64).init(allocator);
    defer mapping.deinit();

    var newMapping = std.AutoHashMap(i64, i64).init(allocator);
    defer newMapping.deinit();

    var seedsIter = mem.split(u8, list.items[0], ":");
    _ = seedsIter.next();
    var seedsRawIter = mem.split(u8, seedsIter.next().?, " ");
    while (seedsRawIter.next()) |seedIndividualRaw| {
        if (seedIndividualRaw.len == 0) {
            continue;
        }
        const seed = try util.toI64(seedIndividualRaw);
        try mapping.put(seed, seed);
    }

    for (list.items, 0..) |line, index| {
        if (line.len == 0 or index <= 1) {
            continue;
        }
        // print("line={s}\n", .{line});
        if (mem.endsWith(u8, line, "map:")) {
            try remap(&mapping, &newMapping);
            newMapping.clearAndFree();
            continue;
        }

        var indexesIter = mem.split(u8, line, " ");
        var destinationStart = try util.toI64(indexesIter.next().?);
        var sourceStart = try util.toI64(indexesIter.next().?);
        var range = try util.toI64(indexesIter.next().?);
        // print("destinationStart={d}, sourceStart={d}, range={d}\n", .{ destinationStart, sourceStart, range });

        var mapIter = mapping.iterator();
        while (mapIter.next()) |entry| {
            var newSource: i64 = entry.value_ptr.*;
            if (newSource == -1) {
                continue;
            }
            if (newSource >= sourceStart and newSource <= sourceStart + range) {
                const offset: i64 = newSource - sourceStart;
                const newDestination: i64 = destinationStart + offset;
                // print("mapping {d}->{d}\n", .{ newSource, newDestination });
                try newMapping.put(newSource, newDestination);
                try mapping.put(entry.key_ptr.*, -1);
            }
        }
    }

    try remap(&mapping, &newMapping);

    var min: ?i64 = null;
    var minIter = mapping.iterator();
    while (minIter.next()) |entry| {
        // print("value={d}\n", .{entry.value_ptr.*});
        if (entry.value_ptr.* == -1) {
            continue;
        }
        if (min) |m| {
            if (entry.value_ptr.* < m) {
                min = entry.value_ptr.*;
            }
        } else {
            min = entry.value_ptr.*;
        }
    }
    return min.?;
}

fn remap(mapping: *std.AutoHashMap(i64, i64), newMapping: *std.AutoHashMap(i64, i64)) !void {
    var mapIter = mapping.iterator();
    while (mapIter.next()) |entry| {
        var newSource = entry.value_ptr.*;
        if (newSource == -1) {
            continue;
        }
        try newMapping.put(newSource, newSource);
    }

    mapping.clearAndFree();

    var newMapIter = newMapping.iterator();
    while (newMapIter.next()) |entry| {
        try mapping.put(entry.key_ptr.*, entry.value_ptr.*);
    }
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 35);
}

test "part 1 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 13);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-5-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(data.lines);
    try std.testing.expectEqual(testValue, 388071289);
}

pub fn part2(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    for (list.items) |line| {
        print("line={s}\n", .{line});
    }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...
    );
    defer list.deinit();

    const testValue: i64 = try part2(list);
    try std.testing.expectEqual(testValue, 0);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-5-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(data.lines);
    // 1361334 is too low
    try std.testing.expectEqual(testValue, 0);
}
