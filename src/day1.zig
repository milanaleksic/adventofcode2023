const std = @import("std");

pub fn firstDay1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    for (list.items) |line| {
        // std.debug.print("processing line {s}\n", .{line});
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
        // std.debug.print("firstChar={}, secondChar={}\n", .{ firstChar, secondChar });
        sum += (firstChar - '0') * 10 + (secondChar - '0');
    }
    return sum;
}

test "test 1-1" {
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append("1abc2");
    try list.append("pqr3stu8vwx");
    try list.append("a1b2c3d4e5f");
    try list.append("treb7uchet");
    const testValue: i64 = try firstDay1(list);
    try std.testing.expect(142 == testValue);
}

pub fn firstDay2(list: std.ArrayList([]const u8)) !usize {
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

test "test 1-2" {
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append("two1nine");
    try list.append("eightwothree");
    try list.append("abcone2threexyz");
    try list.append("xtwone3four");
    try list.append("4nineeightseven2");
    try list.append("zoneight234");
    try list.append("7pqrstsixteen");
    const testValue: usize = try firstDay2(list);
    try std.testing.expectEqual(testValue, 281);
}
