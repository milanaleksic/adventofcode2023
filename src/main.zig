const std = @import("std");
const process = std.process;
const io = std.io;
const allocator = std.heap.page_allocator;
const fs = std.fs;

pub fn main() !void {
    std.debug.print("Advent of Code 2023 by milan@aleksic.dev\n", .{});
    var args = process.args();
    _ = args.skip();
    const dayRaw = args.next() orelse "0";
    const day: i32 = try std.fmt.parseInt(i32, dayRaw, 10);
    const inputFile: []const u8 = args.next() orelse "undefined";
    std.debug.print("Running day {d}, input file={s}\n", .{ day, inputFile });

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    try openFile(inputFile, &list);
    switch (day) {
        1 => {
            const answer = try firstDay1(list);
            std.debug.print("Answer is {d}\n", .{answer});
        },
        else => unreachable,
    }
}

fn firstDay1(list: std.ArrayList([]const u8)) !i64 {
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

fn openFile(inputFile: []const u8, list: *std.ArrayList([]const u8)) !void {
    var file = try fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const buf2 = try allocator.dupe(u8, line);
        try list.append(buf2);
    }
}

test "simple test" {
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append("1abc2");
    try list.append("pqr3stu8vwx");
    try list.append("a1b2c3d4e5f");
    try list.append("treb7uchet");
    const testValue: i64 = try firstDay1(list);
    try std.testing.expect(142 == testValue);
}
