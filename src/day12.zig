const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    var cache = std.AutoHashMap(u64, i64).init(allocator);
    defer cache.deinit();

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

        sum += try run(allocator, &cache, field, groupsNumbers);
    }

    return sum;
}

fn run(allocator: std.mem.Allocator, cache: *std.AutoHashMap(u64, i64), field: []const u8, groupsNumbers: std.ArrayList(u8)) !i64 {
    var newField = try allocator.alloc(u8, field.len);
    std.mem.copy(u8, newField, field);
    defer allocator.free(newField);

    var groups = try allocator.alloc(u8, groupsNumbers.items.len);
    defer allocator.free(groups);
    for (groupsNumbers.items, 0..) |groupNumber, i| {
        groups[i] = groupNumber;
    }

    return try recursiveMatching(allocator, cache, newField, groups);
}

fn recursiveMatching(allocator: std.mem.Allocator, cache: *std.AutoHashMap(u64, i64), field: []u8, groups: []u8) !i64 {
    var hasher = std.hash.Wyhash.init(0);
    hasher.update(field);
    hasher.update(groups);
    const key = hasher.final();

    if (cache.get(key)) |cached| {
        return cached;
    }
    if (field.len == 0) {
        if (groups.len == 0) {
            return 1;
        } else {
            return 0;
        }
    }
    if (field[0] == '?') {
        // here is the main trick in this DP approach: assume both possible values and act accordingly
        field[0] = '.';
        var v1 = try recursiveMatching(allocator, cache, field, groups);

        field[0] = '#';
        var v2 = try recursiveMatching(allocator, cache, field, groups);

        field[0] = '?';

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
    var data = try util.openFile(std.testing.allocator, "data/input-12.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 7195);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    var cache = std.AutoHashMap(u64, i64).init(allocator);
    defer cache.deinit();

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

        sum += try run(allocator, &cache, actualField, groupsNumbers);
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
    var data = try util.openFile(std.testing.allocator, "data/input-12.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 33992866292225);
}
