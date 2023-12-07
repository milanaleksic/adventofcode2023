const std = @import("std");
const process = std.process;
const util = @import("util.zig");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");

pub fn main() !void {
    var args = process.args();
    _ = args.skip();
    const day: i32 = try std.fmt.parseInt(i32, args.next() orelse "0", 10);
    const part: i32 = try std.fmt.parseInt(i32, args.next() orelse "0", 10);
    const inputFile: []const u8 = args.next() orelse "undefined";
    std.debug.print("Advent of Code 2023 by milan@aleksic.dev: running day {d}, part {d}, input file={s}\n", .{ day, part, inputFile });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("LEAKS FOUND");
        }
    }

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
                1 => std.debug.print("Answer is {d}\n", .{try day2.part1(allocator, data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day2.part2(allocator, data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        3 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day3.part1(allocator, data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day3.part2(allocator, data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        4 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day4.part1(allocator, data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day4.part2(allocator, data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        5 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day5.part1(allocator, data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day5.part2(allocator, data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        6 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day6.part1(allocator, data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day6.part2(allocator, data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        7 => {
            switch (part) {
                1 => std.debug.print("Answer is {d}\n", .{try day7.part1(allocator, data.lines)}),
                2 => std.debug.print("Answer is {d}\n", .{try day7.part2(allocator, data.lines)}),
                else => std.debug.print("Unknown / not ready implementation for part {d}\n", .{part}),
            }
        },
        else => std.debug.print("Unknown / not ready implementation for day {d}\n", .{part}),
    }
}
