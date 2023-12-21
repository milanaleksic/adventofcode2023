const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    instructions: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var instructions: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
        for (list.items) |line| {
            var iter = std.mem.split(u8, line, ",");
            while (iter.next()) |split| {
                try instructions.append(split);
            }
        }
        return Self{
            .instructions = instructions,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.instructions.deinit();
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var sum: usize = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.instructions.items) |instr| {
        sum += HASH(instr);
    }

    return sum;
}

fn HASH(instr: []const u8) usize {
    var cur: usize = 0;
    for (instr) |ch| {
        cur += ch;
        cur *= 17;
        cur = @mod(cur, 256);
        // std.debug.print("cur={d}\n", .{cur});
    }
    return cur;
}

test "part 1 test 0" {
    var list = try util.parseToListOfStrings([]const u8,
        \\HASH
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 52);
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 1320);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-15.txt");
    defer data.deinit();

    const testValue: usize = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 506869);
}

const Lens = struct {
    label: []const u8,
    value: usize,
};

const Box = struct {
    const Self = @This();
    list: std.ArrayList(Lens),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .list = std.ArrayList(Lens).init(allocator),
            .allocator = allocator,
        };
    }

    fn remove(self: *Self, label: []const u8) void {
        for (self.list.items, 0..) |lens, i| {
            if (std.mem.eql(u8, lens.label, label)) {
                _ = self.list.orderedRemove(i);
                return;
            }
        }
    }

    fn add(self: *Self, label: []const u8, value: usize) !void {
        for (self.list.items) |*lens| {
            if (std.mem.eql(u8, lens.label, label)) {
                lens.value = value;
                return;
            }
        }
        var lens = Lens{
            .label = label,
            .value = value,
        };
        try self.list.append(lens);
    }

    pub fn deinit(self: *Self) void {
        self.list.deinit();
    }
};

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    var boxes: [256]Box = undefined;
    defer {
        for (0..256) |i| {
            boxes[i].deinit();
        }
    }
    for (0..256) |i| {
        boxes[i] = try Box.init(allocator);
    }

    for (data.instructions.items) |instr| {
        if (std.mem.indexOf(u8, instr, "-")) |loc| {
            const label = instr[0..loc];
            const hash = HASH(label);
            // print("hash for {s} is {d}\n", .{ label, hash });
            boxes[hash].remove(label);
        } else {
            var parts = std.mem.split(u8, instr, "=");
            const label = parts.next().?;
            const value = try util.toUsize(parts.next().?);
            const hash = HASH(label);
            // print("hash for {s} is {d}\n", .{ label, hash });
            try boxes[hash].add(label, value);
        }
    }

    var sum: usize = 0;
    for (boxes, 0..) |box, i| {
        // print("Box {d}: {any}\n", .{ i, box.list.items });
        for (box.list.items, 1..) |lens, slot| {
            sum += (i + 1) * slot * lens.value;
        }
    }
    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 145);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-15.txt");
    defer data.deinit();

    const testValue: usize = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 271384);
}
