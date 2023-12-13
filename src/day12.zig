const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    for (list.items) |line| {
        // print("line={s}\n", .{line});
        var split = mem.split(u8, line, " ");
        var field = split.next().?;

        var groupsNumbers = std.ArrayList(u8).init(allocator);
        defer groupsNumbers.deinit();

        var groupsStrings = mem.split(u8, split.next().?, ",");
        while (groupsStrings.next()) |groupString| {
            try groupsNumbers.append(try util.toU8(groupString));
        }

        sum += try run(allocator, field, groupsNumbers);
    }

    return sum;
}

fn run(allocator: std.mem.Allocator, field: []const u8, groupsNumbers: std.ArrayList(u8)) !i64 {
    var cache = std.StringHashMap(i64).init(allocator);
    defer {
        var iter = cache.keyIterator();
        while (iter.next()) |k| {
            allocator.free(k.*);
        }
        cache.deinit();
    }

    var groups = try allocator.alloc(u8, groupsNumbers.items.len);
    defer allocator.free(groups);
    for (groupsNumbers.items, 0..) |groupNumber, i| {
        groups[i] = groupNumber;
    }

    return try recursiveMatching(allocator, &cache, field, groups);
}

fn recursiveMatching(allocator: std.mem.Allocator, cache: *std.StringHashMap(i64), field: []const u8, groups: []u8) !i64 {
    var key = try std.fmt.allocPrint(allocator, "{s}-{any}", .{ field, groups });
    // std.debug.print("Analyzing field={s} for groups {any}\n", .{ key, groups });
    if (cache.get(key)) |cached| {
        // std.debug.print("Returning cached value {d}\n", .{cached});
        defer allocator.free(key);
        return cached;
    }
    if (field.len == 0) {
        if (groups.len == 0) {
            defer allocator.free(key);
            return 1;
        } else {
            defer allocator.free(key);
            return 0;
        }
    }
    if (field[0] == '?') {
        defer allocator.free(key);
        // here is the main trick in this DP approach: assume both possible values and act accordingly
        var newField = try allocator.alloc(u8, field.len);
        std.mem.copy(u8, newField, field);
        defer allocator.free(newField);

        newField[0] = '.';
        var v1 = try recursiveMatching(allocator, cache, newField, groups);

        newField[0] = '#';
        var v2 = try recursiveMatching(allocator, cache, newField, groups);

        return v1 + v2;
    }
    if (field[0] == '.') {
        // empty space, we can skip the spring matching
        var v = try recursiveMatching(allocator, cache, field[1..], groups);
        try cache.put(key, v);
        return v;
    }
    if (field[0] == '#') {
        // more springs to match, but we used up all our spring sources
        if (groups.len == 0) {
            try cache.put(key, 0);
            return 0;
        }
        // optimization?
        if (field.len < groups[0]) {
            try cache.put(key, 0);
            return 0;
        }
        // optimization?
        if (std.mem.indexOf(u8, field[0..groups[0]], ".")) |_| {
            try cache.put(key, 0);
            return 0;
        }

        if (groups.len > 1) {
            if (field.len < groups[0] + 1 or field[groups[0]] == '#') {
                try cache.put(key, 0);
                return 0;
            }
            var v = try recursiveMatching(allocator, cache, field[groups[0] + 1 ..], groups[1..]);
            try cache.put(key, v);
            return v;
        } else {
            var v = try recursiveMatching(allocator, cache, field[groups[0]..], groups[1..]);
            try cache.put(key, v);
            return v;
        }
    }
    defer allocator.free(key);
    return 0;
}

test "part 1 test 0-1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\# 1
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 1);
}

test "part 1 test 0-2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\.# 1
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 1);
}

test "part 1 test 0-3" {
    var list = try util.parseToListOfStrings([]const u8,
        \\?# 1
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 1);
}

test "part 1 test 0-4" {
    var list = try util.parseToListOfStrings([]const u8,
        \\???.### 1,1,3
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 1);
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 21);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-12-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 7195);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    for (list.items) |line| {
        print("line={s}\n", .{line});
        var split = mem.split(u8, line, " ");
        var field = split.next().?;

        var groupsNumbers = std.ArrayList(u8).init(allocator);
        defer groupsNumbers.deinit();

        var groupsStrings = mem.split(u8, split.next().?, ",");
        while (groupsStrings.next()) |groupString| {
            try groupsNumbers.append(try util.toU8(groupString));
        }

        var actualField: []const u8 = try std.fmt.allocPrint(allocator, "{s}?{s}?{s}?{s}?{s}", .{
            field, field, field, field, field,
        });
        defer allocator.free(actualField);

        const originalSize = groupsNumbers.items.len;
        for (0..4) |_| {
            for (0..originalSize) |j| {
                try groupsNumbers.append(groupsNumbers.items[j]);
            }
        }

        sum += try run(allocator, actualField, groupsNumbers);
    }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 525152);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-12-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 33992866292225);
}
