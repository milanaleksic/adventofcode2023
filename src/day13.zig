const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    rowsSegments: std.ArrayList(std.ArrayList([]const u8)),
    colsSegments: std.ArrayList(std.ArrayList([]const u8)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rowsSegments: std.ArrayList(std.ArrayList([]const u8)) = std.ArrayList(std.ArrayList([]const u8)).init(allocator);
        var rowSegment: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            if (line.len <= 1) {
                try rowsSegments.append(rowSegment);
                rowSegment = std.ArrayList([]const u8).init(allocator);
                // print("starting new segment\n", .{});
            } else {
                try rowSegment.append(line);
            }
        }
        try rowsSegments.append(rowSegment);

        var colsSegments: std.ArrayList(std.ArrayList([]const u8)) = std.ArrayList(std.ArrayList([]const u8)).init(allocator);
        for (rowsSegments.items) |rowSegment2| {
            var colSegment: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
            const rowCount = rowSegment2.items.len;
            for (0..rowSegment2.items[0].len) |j| {
                var col = try allocator.alloc(u8, rowCount);
                for (0..rowCount) |i| {
                    col[i] = rowSegment2.items[i][j];
                }
                // std.debug.print("column={s}\n", .{col});
                try colSegment.append(col);
            }
            try colsSegments.append(colSegment);
        }

        return Self{
            .colsSegments = colsSegments,
            .rowsSegments = rowsSegments,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rowsSegments.items) |segment| {
            segment.deinit();
        }
        self.rowsSegments.deinit();
        for (self.colsSegments.items) |segment| {
            for (segment.items) |col| {
                self.allocator.free(col);
            }
            segment.deinit();
        }
        self.colsSegments.deinit();
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.rowsSegments.items) |segment| {
        sum += calculate(segment, 100);
    }

    for (data.colsSegments.items) |segment| {
        sum += calculate(segment, 1);
    }

    return sum;
}

fn calculate(segment: std.ArrayList([]const u8), multiplier: i64) i64 {
    for (segment.items, 0..) |line, i| {
        const rowCount = segment.items.len;
        if (i >= rowCount - 1) {
            break;
        }
        if (std.mem.eql(u8, line, segment.items[i + 1])) {
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
                return matches * multiplier;
            }
        }
    }
    return 0;
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

    for (data.rowsSegments.items, 0..) |segment, i| {
        const calculated = calculateWithSmudge(segment, 100);
        if (calculated > 0) {
            sum += calculated;
        } else {
            sum += calculateWithSmudge(data.colsSegments.items[i], 1);
        }
    }

    return sum;
}

fn calculateWithSmudge(segment: std.ArrayList([]const u8), multiplier: i64) i64 {
    for (segment.items, 0..) |line, i| {
        // print("analyzing line {s}\n", .{line});
        const rowCount = segment.items.len;
        if (i >= rowCount - 1) {
            break;
        }
        var numberOfSmudges: usize = 0;
        var isEqual = std.mem.eql(u8, line, segment.items[i + 1]);
        if (!isEqual) {
            if (identicalWithASingleSmudge(line, segment.items[i + 1])) {
                numberOfSmudges += 1;
                isEqual = true;
            }
        }
        if (!isEqual) {
            continue;
        }
        var matches: i64 = 1;
        for (1..rowCount) |j| {
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
                    } else if (identicalWithASingleSmudge(segment.items[j2Safe], segment.items[j1Safe])) {
                        if (numberOfSmudges > 1) {
                            matches = 0;
                            break;
                        } else {
                            numberOfSmudges += 1;
                        }
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
        if (matches > 0 and numberOfSmudges <= 1) {
            // print("matches found {d}\n", .{matches * multiplier});
            return matches * multiplier;
        }
    }
    return 0;
}

fn identicalWithASingleSmudge(lhs: []const u8, rhs: []const u8) bool {
    var smudgeUsed = false;
    for (lhs, rhs) |char1, char2| {
        if (char1 != char2) {
            if (smudgeUsed) {
                return false;
            } else {
                smudgeUsed = true;
            }
        }
    }
    return true;
}

test "part 2 test 1" {
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

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 400);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-13-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    // 41878 is too high
    try std.testing.expectEqual(testValue, -1);
}
