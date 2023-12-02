const std = @import("std");

const allowedRed = 12;
const allowedGreen = 13;
const allowedBlue = 14;

pub fn secondDay1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    for (list.items) |line| {
        // std.debug.print("line={s}\n", .{line});
        var forbid = false;
        if (std.mem.indexOf(u8, line, ":")) |indexOfColon| {
            if (std.mem.indexOf(u8, line, " ")) |indexOfSpace| {
                // std.debug.print("indexOfColon={d}, indexOfSpace={d}, game={d}\n", .{ indexOfColon, indexOfSpace, game });
                // std.debug.print("game={s}\n", .{line[indexOfSpace + 1 .. indexOfColon]});
                const game = try std.fmt.parseInt(i32, line[indexOfSpace + 1 .. indexOfColon], 10);

                var lastExtractBegin = indexOfColon + 2;
                for (line[indexOfColon + 2 ..], indexOfColon + 2..) |char, i| {
                    // std.debug.print("char='{d}'\n", .{char});
                    if (char == ',' or char == ';') {
                        const next = try forbidOnLine(line, lastExtractBegin, i);
                        if (next[0]) {
                            forbid = true;
                        }
                        lastExtractBegin = next[1];
                    }
                }
                const next = try forbidOnLine(line, lastExtractBegin, line.len);
                if (next[0]) {
                    forbid = true;
                }
                if (!forbid) {
                    sum += game;
                }
            }
        }
    }
    return sum;
}

fn forbidOnLine(line: []const u8, lastExtractBegin: usize, i: usize) !struct { bool, usize } {
    const extract = line[lastExtractBegin..i];
    var lineShouldBeForbidden = false;
    // std.debug.print("extract='{s}'\n", .{extract});
    var split = std.mem.split(u8, extract, " ");
    if (split.next()) |number| {
        const count = try std.fmt.parseInt(i32, number, 10);
        if (split.next()) |color| {
            if (std.mem.eql(u8, color, "red") and count > allowedRed) {
                lineShouldBeForbidden = true;
            } else if (std.mem.eql(u8, color, "green") and count > allowedGreen) {
                lineShouldBeForbidden = true;
            } else if (std.mem.eql(u8, color, "blue") and count > allowedBlue) {
                lineShouldBeForbidden = true;
            }
            // std.debug.print("color='{s}', count={d}\n", .{ color, count });
        }
    }
    return .{ lineShouldBeForbidden, i + 2 };
}

test "test 2-1" {
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");
    try list.append("Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue");
    try list.append("Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red");
    try list.append("Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red");
    try list.append("Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green");
    const testValue: i64 = try secondDay1(list);
    try std.testing.expectEqual(testValue, 8);
}

pub fn secondDay2(list: std.ArrayList([]const u8)) !usize {
    const words = [9][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var sum: usize = 0;
    for (list.items) |line| {
        // std.debug.print("processing line {s}\n", .{line});
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
                    // std.debug.print("i={d}, word={s}, char={}\n", .{ i, word, char });
                    if (i >= word.len - 1) {
                        const extract = line[i + 1 - word.len .. i + 1];
                        // std.debug.print("extract={s}, comparing for {s}\n", .{ extract, word });
                        if (std.mem.eql(u8, word, extract)) {
                            if (firstChar == 0) {
                                firstChar = j;
                            }
                            secondChar = j;
                        }
                    }
                }
            }
        }
        // std.debug.print("firstChar={}, secondChar={}\n", .{ firstChar, secondChar });
        sum += firstChar * 10 + secondChar;
    }
    return sum;
}

test "test 2-2" {
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append("two1nine");
    try list.append("eightwothree");
    try list.append("abcone2threexyz");
    try list.append("xtwone3four");
    try list.append("4nineeightseven2");
    try list.append("zoneight234");
    try list.append("7pqrstsixteen");
    const testValue: usize = try secondDay2(list);
    try std.testing.expectEqual(testValue, 281);
}
