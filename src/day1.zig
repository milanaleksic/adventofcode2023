const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    for (list.items) |line| {
        // print("processing line {s}\n", .{line});
        var firstChar: u8 = 0;
        var secondChar: u8 = 0;
        for (line) |char| {
            if (char >= '0' and char <= '9') {
                if (firstChar == 0) {
                    firstChar = char;
                }
                secondChar = char;
            }
        }
        // print("firstChar={}, secondChar={}\n", .{ firstChar, secondChar });
        sum += (firstChar - '0') * 10 + (secondChar - '0');
    }
    return sum;
}

test "part 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expect(142 == testValue);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-1-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(data.lines);
    try std.testing.expectEqual(testValue, 55208);
}

pub fn part2(list: std.ArrayList([]const u8)) !usize {
    const words = [9][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var sum: usize = 0;
    for (list.items) |line| {
        // print("processing line {s}\n", .{line});
        var firstChar: usize = 0;
        var secondChar: usize = 0;
        for (line, 0..) |char, i| {
            if (char >= '0' and char <= '9') {
                if (firstChar == 0) {
                    firstChar = char - @as(i8, '0');
                }
                secondChar = char - @as(i8, '0');
            } else {
                for (words, 1..) |word, j| {
                    // print("i={d}, word={s}, char={}\n", .{ i, word, char });
                    if (i >= word.len - 1) {
                        const extract = line[i + 1 - word.len .. i + 1];
                        // print("extract={s}, comparing for {s}\n", .{ extract, word });
                        if (mem.eql(u8, word, extract)) {
                            if (firstChar == 0) {
                                firstChar = j;
                            }
                            secondChar = j;
                        }
                    }
                }
            }
        }
        // print("firstChar={}, secondChar={}\n", .{ firstChar, secondChar });
        sum += firstChar * 10 + secondChar;
    }
    return sum;
}

test "part 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    );
    defer list.deinit();

    const testValue: usize = try part2(list);
    try std.testing.expectEqual(testValue, 281);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-1-1.txt");
    defer data.deinit();

    const testValue: usize = try part2(data.lines);
    try std.testing.expectEqual(testValue, 54578);
}
