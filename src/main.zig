const std = @import("std");
const process = std.process;
const allocator = std.heap.page_allocator;
const util = @import("util.zig");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");

pub fn main() !void {
    var args = process.args();
    _ = args.skip();
    const day: i32 = try std.fmt.parseInt(i32, args.next() orelse "0", 10);
    const part: i32 = try std.fmt.parseInt(i32, args.next() orelse "0", 10);
    const inputFile: []const u8 = args.next() orelse "undefined";
    std.debug.print("Advent of Code 2023 by milan@aleksic.dev: running day {d}, part {d}, input file={s}\n", .{ day, part, inputFile });

    var data = try util.openFile(allocator, inputFile);
    defer data.deinit();

    switch (day) {
        1 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day1.part1(data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day1.part2(data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        2 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day2.part1(data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day2.part2(data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        else => std.debug.print("Unknown / not ready implementation for day {d}\n", .{part}),
    }
}
