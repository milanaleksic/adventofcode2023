const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const allowedRed = 12;
const allowedGreen = 13;
const allowedBlue = 14;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    for (list.items) |line| {
        // print("line={s}\n", .{line});
        if (mem.indexOf(u8, line, ":")) |indexOfColon| {
            if (mem.indexOf(u8, line, " ")) |indexOfSpace| {
                var forbid = false;
                // print("indexOfColon={d}, indexOfSpace={d}, game={d}\n", .{ indexOfColon, indexOfSpace, game });
                // print("game={s}\n", .{line[indexOfSpace + 1 .. indexOfColon]});
                const game = try parseInt(i32, line[indexOfSpace + 1 .. indexOfColon], 10);

                var lastExtractBegin = indexOfColon + 2;
                for (line[indexOfColon + 2 ..], indexOfColon + 2..) |char, i| {
                    // print("char='{d}'\n", .{char});
                    if (char == ',' or char == ';') {
                        forbid = forbid or try forbidOnLine(line, lastExtractBegin, i);
                        lastExtractBegin = i + 2;
                    }
                }
                forbid = forbid or try forbidOnLine(line, lastExtractBegin, line.len);
                if (!forbid) {
                    sum += game;
                }
            }
        }
    }
    return sum;
}

fn forbidOnLine(line: []const u8, lastExtractBegin: usize, i: usize) !bool {
    const extract = line[lastExtractBegin..i];
    // print("extract='{s}'\n", .{extract});
    var split = mem.split(u8, extract, " ");
    if (split.next()) |number| {
        const count = try parseInt(i32, number, 10);
        if (split.next()) |color| {
            if (mem.eql(u8, color, "red") and count > allowedRed) {
                return true;
            } else if (mem.eql(u8, color, "green") and count > allowedGreen) {
                return true;
            } else if (mem.eql(u8, color, "blue") and count > allowedBlue) {
                return true;
            }
            // print("color='{s}', count={d}\n", .{ color, count });
        }
    }
    return false;
}

test "part 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 8);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-2-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(data.lines);
    try std.testing.expectEqual(testValue, 3035);
}

pub fn part2(list: std.ArrayList([]const u8)) !usize {
    var sum: usize = 0;
    for (list.items) |line| {
        // print("line={s}\n", .{line});
        if (mem.indexOf(u8, line, ":")) |indexOfColon| {
            var minRed: usize = 0;
            var minGreen: usize = 0;
            var minBlue: usize = 0;
            // print("indexOfColon={d}, indexOfSpace={d}, game={d}\n", .{ indexOfColon, indexOfSpace, game });
            // print("game={s}\n", .{line[indexOfSpace + 1 .. indexOfColon]});
            var lastExtractBegin = indexOfColon + 2;
            for (line[indexOfColon + 2 ..], indexOfColon + 2..) |char, i| {
                // print("char='{d}'\n", .{char});
                if (char == ',' or char == ';') {
                    const next = try countsOnLine(line, lastExtractBegin, i);
                    if (next.red > minRed) {
                        minRed = next.red;
                    }
                    if (next.green > minGreen) {
                        minGreen = next.green;
                    }
                    if (next.blue > minBlue) {
                        minBlue = next.blue;
                    }
                    lastExtractBegin = i + 2;
                }
            }
            const next = try countsOnLine(line, lastExtractBegin, line.len);
            if (next.red > minRed) {
                minRed = next.red;
            }
            if (next.green > minGreen) {
                minGreen = next.green;
            }
            if (next.blue > minBlue) {
                minBlue = next.blue;
            }
            sum += minRed * minGreen * minBlue;
        }
    }
    return sum;
}

fn countsOnLine(line: []const u8, lastExtractBegin: usize, i: usize) !struct { red: usize, green: usize, blue: usize } {
    const extract = line[lastExtractBegin..i];
    var countRed: usize = 0;
    var countGreen: usize = 0;
    var countBlue: usize = 0;
    // print("extract='{s}'\n", .{extract});
    var split = mem.split(u8, extract, " ");
    if (split.next()) |number| {
        const count = try parseInt(usize, number, 10);
        if (split.next()) |color| {
            if (mem.eql(u8, color, "red")) {
                countRed = count;
            } else if (mem.eql(u8, color, "green")) {
                countGreen = count;
            } else if (mem.eql(u8, color, "blue")) {
                countBlue = count;
            }
            // print("color='{s}', count={d}\n", .{ color, count });
        }
    }
    return .{ .red = countRed, .green = countGreen, .blue = countBlue };
}

test "part 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    );
    defer list.deinit();

    const testValue: usize = try part2(list);
    try std.testing.expectEqual(testValue, 2286);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-2-1.txt");
    defer data.deinit();

    const testValue: usize = try part2(data.lines);
    try std.testing.expectEqual(testValue, 66027);
}
