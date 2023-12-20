const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
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

    const testValue: i64 = try part1(std.testing.allocator, list);
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

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 13);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-5.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 388071289);
}

const Range = struct {
    start: i64,
    end: i64,
};

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var mapping = std.AutoHashMap(Range, ?Range).init(allocator);
    defer mapping.deinit();

    var newMapping = std.AutoHashMap(Range, ?Range).init(allocator);
    defer newMapping.deinit();

    var seedsIter = mem.split(u8, list.items[0], ":");
    _ = seedsIter.next();
    var seedsRawIter = mem.split(u8, seedsIter.next().?, " ");
    while (seedsRawIter.next()) |seedIndividualRawStart| {
        if (seedIndividualRawStart.len == 0) {
            continue;
        }
        const seedIndividualStart = try util.toI64(seedIndividualRawStart);
        var seedsRawRange = seedsRawIter.next();
        const seedRange = try util.toI64(seedsRawRange.?);
        var range = Range{ .start = seedIndividualStart, .end = seedIndividualStart + seedRange - 1 };
        try mapping.put(range, range);
    }

    for (list.items, 0..) |line, index| {
        if (line.len == 0 or index <= 1) {
            continue;
        }
        if (mem.endsWith(u8, line, "map:")) {
            try remapRange(&mapping, &newMapping);
            // printRangeMap(&mapping);
            newMapping.clearAndFree();
            continue;
        }

        var indexesIter = mem.split(u8, line, " ");
        var destinationStart = try util.toI64(indexesIter.next().?);
        var sourceStart = try util.toI64(indexesIter.next().?);
        var range = try util.toI64(indexesIter.next().?) - 1;

        var mapIter = mapping.iterator();
        while (mapIter.next()) |entry| {
            var key = entry.key_ptr.*;
            if (entry.value_ptr.*) |newSourceRange| {
                if (newSourceRange.start > sourceStart + range or newSourceRange.end <= sourceStart) {
                    continue;
                }
                const offset: i64 = destinationStart - sourceStart;
                // print("Splitting range {d}-{d} because of {d}-{d} (offset: {d})\n", .{ sourceStart, @min(sourceStart + range, newSourceRange.end), sourceStart, sourceStart + range, offset });
                // print("  segment 1: {d}-{d} -> {d}-{d}\n", .{ sourceStart, @min(sourceStart + range, newSourceRange.end), sourceStart + offset, @min(sourceStart + range, newSourceRange.end) + offset });
                try newMapping.put(.{
                    .start = @max(newSourceRange.start, sourceStart),
                    .end = @min(sourceStart + range, newSourceRange.end),
                }, .{
                    .start = @max(newSourceRange.start, sourceStart) + offset,
                    .end = @min(sourceStart + range, newSourceRange.end) + offset,
                });
                if (sourceStart - 1 >= newSourceRange.start) {
                    // print("  segment 2 (copy): {d}-{d}\n", .{ newSourceRange.start, sourceStart - 1 });
                    try mapping.put(.{
                        .start = newSourceRange.start,
                        .end = sourceStart - 1,
                    }, .{
                        .start = newSourceRange.start,
                        .end = sourceStart - 1,
                    });
                }
                if (newSourceRange.end >= sourceStart + range + 1) {
                    // print("  segment 3 (copy): {d}-{d}\n", .{ sourceStart + range + 1, newSourceRange.end });
                    try mapping.put(.{
                        .start = sourceStart + range + 1,
                        .end = newSourceRange.end,
                    }, .{
                        .start = sourceStart + range + 1,
                        .end = newSourceRange.end,
                    });
                }
                try mapping.put(key, null);
            }
        }
    }

    try remapRange(&mapping, &newMapping);

    // printRangeMap(&mapping);

    var min: ?Range = null;
    var minIter = mapping.iterator();
    while (minIter.next()) |entry| {
        if (entry.value_ptr.*) |range| {
            if (min) |m| {
                if (range.start < m.start) {
                    min = range;
                }
            } else {
                min = range;
            }
        }
    }
    return min.?.start;
}

fn printRangeMap(mapping: *std.AutoHashMap(Range, ?Range)) void {
    print("\n*** Printing range map ***\n", .{});
    var iter = mapping.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.*) |range| {
            print("{d}-{d} -> {d}-{d}\n", .{ entry.key_ptr.*.start, entry.key_ptr.*.end, range.start, range.end });
        } else {
            print("{d}-{d} is empty\n", .{ entry.key_ptr.*.start, entry.key_ptr.*.end });
        }
    }
}

fn remapRange(mapping: *std.AutoHashMap(Range, ?Range), newMapping: *std.AutoHashMap(Range, ?Range)) !void {
    var mapIter = mapping.iterator();
    while (mapIter.next()) |entry| {
        if (entry.value_ptr.*) |newSourceRaw| {
            try newMapping.put(newSourceRaw, newSourceRaw);
        }
    }

    mapping.clearAndFree();

    var newMapIter = newMapping.iterator();
    while (newMapIter.next()) |entry| {
        try mapping.put(entry.key_ptr.*, entry.value_ptr.*);
    }
}

test "part 2 test 1" {
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

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 46);
}

test "part 2 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 100 10
        \\
        \\seed-to-soil map:
        \\0 95 7
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 5);
}

test "part 2 test 3" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 100 10
        \\
        \\seed-to-soil map:
        \\0 105 7
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 0);
}

test "part 2 test 4" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 100 10
        \\
        \\seed-to-soil map:
        \\117 102 2
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 100);
}

test "part 2 test 5" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 100 10
        \\
        \\seed-to-soil map:
        \\125 95 20
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 130);
}

test "part 2 test 6" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 100 10
        \\
        \\seed-to-soil map:
        \\125 101 11
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 100);
}

test "part 2 test 7" {
    var list = try util.parseToListOfStrings([]const u8,
        \\seeds: 100 10
        \\
        \\seed-to-soil map:
        \\125 100 5
        \\120 105 5
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 120);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-5.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    // 638999091 is too high
    try std.testing.expectEqual(testValue, 84206669);
}
