const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const NodeType = enum {
    NS,
    WE,
    NWSE,
    NESW,
};

const Node = struct {
    const Self = @This();
    nodeType: ?NodeType,
    alreadyVisitedDirections: std.ArrayList(Direction),

    pub fn energize(self: *Self, direction: Direction) !bool {
        if (std.mem.indexOf(Direction, self.alreadyVisitedDirections.items, &[_]Direction{direction})) |_| {
            return false;
        }
        try self.alreadyVisitedDirections.append(direction);
        return true;
    }

    pub fn energized(self: Self) bool {
        return self.alreadyVisitedDirections.items.len > 0;
    }
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    rows: std.ArrayList(std.ArrayList(Node)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rows: std.ArrayList(std.ArrayList(Node)) = std.ArrayList(std.ArrayList(Node)).init(allocator);
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var row: std.ArrayList(Node) = std.ArrayList(Node).init(allocator);
            for (line) |ch| {
                const nodeType: ?NodeType = (switch (ch) {
                    '/' => NodeType.NESW,
                    '\\' => NodeType.NWSE,
                    '|' => NodeType.NS,
                    '-' => NodeType.WE,
                    '.' => null,
                    else => @panic("unexpected input"),
                });
                try row.append(Node{
                    .nodeType = nodeType,
                    .alreadyVisitedDirections = std.ArrayList(Direction).init(allocator),
                });
            }
            try rows.append(row);
        }
        return Self{
            .rows = rows,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |row| {
            for (row.items) |node| {
                node.alreadyVisitedDirections.deinit();
            }
            row.deinit();
        }
        self.rows.deinit();
    }

    pub fn printMap(self: *Self, energizedPrioritized: bool) void {
        print("\n", .{});
        for (self.rows.items) |row| {
            for (row.items) |ch| {
                if (ch.nodeType) |nodeType| {
                    if (energizedPrioritized) {
                        if (ch.energized()) {
                            print("#", .{});
                        } else {
                            print(" ", .{});
                        }
                    } else {
                        const c: u16 = switch (nodeType) {
                            NodeType.NS => '|',
                            NodeType.WE => '-',
                            NodeType.NESW => '╱',
                            NodeType.NWSE => '╲',
                        };
                        print("{u}", .{c});
                    }
                } else if (ch.energized()) {
                    print("#", .{});
                } else {
                    print(" ", .{});
                }
            }
            print("\n", .{});
        }
    }
};

const Direction = enum {
    N,
    S,
    W,
    E,
};

const Location = struct {
    x: usize,
    y: usize,
};

const Ray = struct {
    const Self = @This();
    direction: Direction,
    location: ?Location,

    pub fn step(self: Self, data: Data) ?Location {
        if (self.location) |loc| {
            return switch (self.direction) {
                Direction.N => if (loc.y == 0) null else Location{
                    .x = loc.x,
                    .y = loc.y - 1,
                },
                Direction.W => if (loc.x == 0) null else Location{
                    .x = loc.x - 1,
                    .y = loc.y,
                },
                Direction.S => if (loc.y == data.rows.items.len - 1) null else Location{
                    .x = loc.x,
                    .y = loc.y + 1,
                },
                Direction.E => if (loc.x == data.rows.items[0].items.len - 1) null else Location{
                    .x = loc.x + 1,
                    .y = loc.y,
                },
            };
        } else {
            return Location{
                .x = 0,
                .y = 0,
            };
        }
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    var rays = std.ArrayList(Ray).init(allocator);
    defer rays.deinit();

    // data.printMap(false);

    _ = try data.rows.items[0].items[0].energize(Direction.E);
    try runRay(Ray{
        .location = null,
        .direction = Direction.E,
    }, &data);

    // data.printMap(true);

    var sum: i64 = 0;
    for (data.rows.items) |row| {
        for (row.items) |node| {
            if (node.energized()) {
                sum += 1;
            }
        }
    }

    return sum;
}

fn runRay(ray: Ray, data: *Data) !void {
    // data.printMap(false);
    if (ray.step(data.*)) |newLoc| {
        var newNode = &data.rows.items[newLoc.y].items[newLoc.x];

        if (newNode.nodeType) |newNodeType| {
            _ = try newNode.energize(ray.direction);
            switch (newNodeType) {
                NodeType.NS => {
                    if (ray.direction == Direction.N or ray.direction == Direction.S) {
                        try runRay(Ray{
                            .location = newLoc,
                            .direction = ray.direction,
                        }, data);
                    } else {
                        try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.N,
                        }, data);
                        try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.S,
                        }, data);
                    }
                },
                NodeType.WE => {
                    if (ray.direction == Direction.W or ray.direction == Direction.E) {
                        try runRay(Ray{
                            .location = newLoc,
                            .direction = ray.direction,
                        }, data);
                    } else {
                        try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.W,
                        }, data);
                        try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.E,
                        }, data);
                    }
                },
                NodeType.NWSE => {
                    switch (ray.direction) {
                        Direction.N => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.W,
                        }, data),
                        Direction.W => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.N,
                        }, data),
                        Direction.S => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.E,
                        }, data),
                        Direction.E => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.S,
                        }, data),
                    }
                },
                NodeType.NESW => {
                    switch (ray.direction) {
                        Direction.N => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.E,
                        }, data),
                        Direction.W => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.S,
                        }, data),
                        Direction.S => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.W,
                        }, data),
                        Direction.E => try runRay(Ray{
                            .location = newLoc,
                            .direction = Direction.N,
                        }, data),
                    }
                },
            }
        } else {
            if (try newNode.energize(ray.direction)) {
                try runRay(Ray{
                    .location = newLoc,
                    .direction = ray.direction,
                }, data);
            }
        }
    }
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\.|...\....
        \\|.-.\.....
        \\.....|-...
        \\........|.
        \\..........
        \\.........\
        \\..../.\\..
        \\.-.-/..|..
        \\.|....-|.\
        \\..//.|....
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 46);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-16.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    // 64 is not correct
    try std.testing.expectEqual(testValue, 8112);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    // access input data...
    // for (data.rows.items) |rowData| {

    // }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, -1);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-16.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
