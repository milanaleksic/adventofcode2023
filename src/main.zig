const std = @import("std");
const process = std.process;
const allocator = std.heap.page_allocator;
const util = @import("util.zig");
const day1 = @import("day1.zig");

pub fn main() !void {
    std.debug.print("Advent of Code 2023 by milan@aleksic.dev\n", .{});
    var args = process.args();
    _ = args.skip();
    const day: i32 = try std.fmt.parseInt(i32, args.next() orelse "0", 10);
    const part: i32 = try std.fmt.parseInt(i32, args.next() orelse "0", 10);
    const inputFile: []const u8 = args.next() orelse "undefined";
    std.debug.print("Running day {d}, part {d}, input file={s}\n", .{ day, part, inputFile });

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    try util.openFile(inputFile, &list);
    switch (day) {
        1 => {
            switch (part) {
                1 => {
                    const answer = try day1.firstDay1(list);
                    std.debug.print("Answer is {d}\n", .{answer});
                },
                2 => {
                    const answer = try day1.firstDay2(list);
                    std.debug.print("Answer is {d}\n", .{answer});
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}
