const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const allocator = std.heap.page_allocator;

const allowedRed = 12;
const allowedGreen = 13;
const allowedBlue = 14;

pub fn part1(list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;
    const cols = list.items[0].len;
    const rows = list.items.len;
    var data: [][]u8 = try allocator.alloc([]u8, rows);
    for (list.items, 0..) |line, row| {
        // print("\nline={s}", .{line});
        data[row] = try allocator.alloc(u8, cols);
        for (line, 0..) |c, col| {
            data[row][col] = c;
        }
    }
    defer {
        for (data) |line| {
            allocator.free(line);
        }
        allocator.free(data);
    }

    // printMatrix(data);

    var x: usize = 0;
    var y: usize = 0;
    while (y < rows) {
        while (x < cols) {
            const c = data[y][x];
            if (isDigit(c)) {
                const beginDigit = x;
                while (isDigit(data[y][x])) {
                    if (data[y][x] == '-') {
                        if (x > beginDigit) {
                            break;
                        }
                    }
                    x += 1;
                    if (x == cols) {
                        break;
                    }
                }
                const endDigit = x;
                if (beginDigit + 1 == endDigit and c == '-') {
                    continue;
                }
                // print("beginDigit={d}, endDigit={d}\n", .{ beginDigit, endDigit });

                const beginX = if (beginDigit == 0) 0 else beginDigit - 1;
                const endX = if (endDigit >= cols - 1) cols else endDigit + 2;
                const beginY = if (y == 0) y else y - 1;
                const endY = if (y >= rows - 1) rows else y + 2;

                // print("looking between x={d}..{d} and y={d}..{d}\n", .{ beginX, endX, beginY, endY });
                outside: for (beginY..endY) |yi| {
                    for (beginX..endX) |xi| {
                        // print("looking at x={d} y={d}, data={c}\n", .{ xi, yi, data[yi][xi] });
                        if (isSymbol(data[yi][xi])) {
                            // print("parsing '{s}'\n", .{data[y][beginDigit..endDigit]});
                            const number = try parseInt(i64, data[y][beginDigit..endDigit], 10);
                            print("{d}\n", .{number});
                            sum += number;
                            break :outside;
                        }
                    }
                }
                // print("{s}", .{data[y][beginDigit..endDigit]});
            } else {
                // print(" ", .{});
            }
            x += 1;
        }
        // print("\n", .{});
        y += 1;
        x = 0;
    }

    return sum;
}

fn isDigit(c: u8) bool {
    return (c >= '0' and c <= '9') or c == '-';
}

fn isSymbol(c: u8) bool {
    return (c < '0' or c > '9') and (c != '.') and (c != '\n');
}

fn printMatrix(data: [][]u8) void {
    for (data) |line| {
        for (line) |c| {
            print("{c}", .{c});
        }
        print("\n", .{});
    }
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 4361);
}

test "part 1 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\467..114..
        \\...*......
        \\..35-.633.
        \\......-...
        \\617*......
        \\.....+.58.
        \\.-592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    defer list.deinit();

    const testValue: i64 = try part1(list);
    try std.testing.expectEqual(testValue, 3177);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-3-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(data.lines);
    // 513328 is too low
    // 516161 is too high
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
