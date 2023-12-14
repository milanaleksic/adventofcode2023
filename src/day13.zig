const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    segments: std.ArrayList(std.ArrayList([]const u8)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var segments: std.ArrayList(std.ArrayList([]const u8)) = std.ArrayList(std.ArrayList([]const u8)).init(allocator);
        var segment: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
        for (list.items) |line| {
            print("line={s}\n", .{line});
            if (line.len <= 1) {
                try segments.append(segment);
                segment = std.ArrayList([]const u8).init(allocator);
                print("starting new segment\n", .{});
            } else {
                try segment.append(line);
            }
        }
        try segments.append(segment);
        return Self{
            .segments = segments,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.segments.items) |segment| {
            segment.deinit();
        }
        self.segments.deinit();
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.segments.items) |segment| {
        for (segment.items, 0..) |line, i| {
            const rowCount = segment.items.len;
            if (i >= rowCount - 1) {
                break;
            }
            print("comparing {s} and {s}\n", .{ line, segment.items[i + 1] });
            if (std.mem.eql(u8, line, segment.items[i + 1])) {
                print("match!\n", .{});
                var matches: i64 = 0;
                for (0..rowCount) |j| {
                    const ii64: i64 = @bitCast(i);
                    const ji64: i64 = @bitCast(j);
                    const j1: i64 = ii64 - ji64;
                    const j2: i64 = ii64 + ji64 + 1;
                    if (j1 >= 0) {
                        if (j2 >= rowCount) {
                            matches += 1;
                        } else {
                            const j1Safe: u64 = @bitCast(j1);
                            const j2Safe: u64 = @bitCast(j2);
                            if (std.mem.eql(u8, segment.items[j2Safe], segment.items[j1Safe])) {
                                matches += 1;
                            } else {
                                matches = 0;
                                break;
                            }
                        }
                    } else {
                        break;
                    }
                }
                if (matches > 0) {
                    sum += matches * 100;
                    break;
                }
            }
        }
    }

    return sum;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 405);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-13-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    // access input data...
    // for (data.rows.items) |rowData| {

    // }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, -1);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-13-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}