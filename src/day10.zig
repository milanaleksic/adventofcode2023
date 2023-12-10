const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Direction = enum {
    North,
    West,
    South,
    East,
};

const NodeType = enum {
    NW,
    NE,
    SE,
    SW,
    WE,
    NS,
    START,
    GROUND,

    pub fn fromChar(x: u8) NodeType {
        return switch (x) {
            '|' => NodeType.NS,
            '-' => NodeType.WE,
            'L' => NodeType.NE,
            'J' => NodeType.NW,
            '7' => NodeType.SW,
            'F' => NodeType.SE,
            'S' => NodeType.START,
            '.' => NodeType.GROUND,
            else => unreachable,
        };
    }

    pub fn chooseStartDirection(self: NodeType) Direction {
        return if (self == NodeType.NW or self == NodeType.NS or self == NodeType.NE)
            Direction.North
        else if (self == NodeType.SW or self == NodeType.WE)
            Direction.West
        else
            Direction.South;
    }
};

const Loc = struct {
    x: usize,
    y: usize,
};

const NodeWithDirection = struct {
    node: *Node,
    direction: Direction,
};

const Node = struct {
    nodeType: NodeType,
    distance: i64,
    location: Loc,
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    start: Loc,
    rows: std.ArrayList(std.ArrayList(Node)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var start: ?Loc = null;
        var rows: std.ArrayList(std.ArrayList(Node)) = try std.ArrayList(std.ArrayList(Node)).initCapacity(allocator, list.items.len);

        for (list.items, 0..) |line, y| {
            // print("line={s}\n", .{line});
            var row: std.ArrayList(Node) = try std.ArrayList(Node).initCapacity(allocator, line.len);
            for (line, 0..) |char, x| {
                const nodeType = NodeType.fromChar(char);
                const loc = Loc{
                    .x = x,
                    .y = y,
                };
                if (nodeType == NodeType.START) {
                    start = loc;
                }
                var node: Node = Node{
                    .nodeType = nodeType,
                    .distance = 0,
                    .location = loc,
                };
                try row.append(node);
            }
            try rows.append(row);
        }
        return Self{
            .rows = rows,
            .allocator = allocator,
            .start = start.?,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |row| {
            row.deinit();
        }
        self.rows.deinit();
    }

    pub fn figureOutStartingPoint(self: *Self) NodeType {
        var north = false;
        var west = false;
        var south = false;
        var east = false;
        const start = self.start;
        if (start.y > 0) {
            const northNodeType = self.rows.items[start.y - 1].items[start.x].nodeType;
            north = northNodeType == NodeType.SE or northNodeType == NodeType.SW or northNodeType == NodeType.NS;
        }
        if (start.y < self.rows.items.len - 1) {
            const southNodeType = self.rows.items[start.y + 1].items[start.x].nodeType;
            south = southNodeType == NodeType.NW or southNodeType == NodeType.NS or southNodeType == NodeType.NE;
        }
        if (start.x > 0) {
            const westNodeType = self.rows.items[start.y].items[start.x - 1].nodeType;
            west = westNodeType == NodeType.SE or westNodeType == NodeType.NE or westNodeType == NodeType.WE;
        }
        if (start.x < self.rows.items[start.y].items.len - 1) {
            const eastNodeType = self.rows.items[start.y].items[start.x + 1].nodeType;
            east = eastNodeType == NodeType.SW or eastNodeType == NodeType.NW or eastNodeType == NodeType.WE;
        }
        return if (north and west)
            NodeType.NW
        else if (north and east)
            NodeType.NE
        else if (south and west)
            NodeType.SW
        else if (south and east)
            NodeType.SE
        else
            unreachable;
    }

    pub fn nextNode(self: *Self, loc: Loc, direction: Direction) NodeWithDirection {
        const node = self.rows.items[loc.y].items[loc.x];
        // print("Approaching {} from {}\n", .{ node, direction });
        return switch (node.nodeType) {
            NodeType.NW => if (direction == Direction.North)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y].items[loc.x - 1],
                    .direction = Direction.East,
                }
            else if (direction == Direction.West)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y - 1].items[loc.x],
                    .direction = Direction.South,
                }
            else
                undefined,
            NodeType.NE => if (direction == Direction.North)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y].items[loc.x + 1],
                    .direction = Direction.West,
                }
            else if (direction == Direction.East)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y - 1].items[loc.x],
                    .direction = Direction.South,
                }
            else
                undefined,
            NodeType.SE => if (direction == Direction.South)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y].items[loc.x + 1],
                    .direction = Direction.West,
                }
            else if (direction == Direction.East)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y + 1].items[loc.x],
                    .direction = Direction.North,
                }
            else
                undefined,
            NodeType.SW => if (direction == Direction.South)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y].items[loc.x - 1],
                    .direction = Direction.East,
                }
            else if (direction == Direction.West)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y + 1].items[loc.x],
                    .direction = Direction.North,
                }
            else
                undefined,
            NodeType.WE => if (direction == Direction.West)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y].items[loc.x + 1],
                    .direction = Direction.West,
                }
            else if (direction == Direction.East)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y].items[loc.x - 1],
                    .direction = Direction.East,
                }
            else
                undefined,
            NodeType.NS => if (direction == Direction.North)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y + 1].items[loc.x],
                    .direction = Direction.North,
                }
            else if (direction == Direction.South)
                NodeWithDirection{
                    .node = &self.rows.items[loc.y - 1].items[loc.x],
                    .direction = Direction.South,
                }
            else
                undefined,
            else => undefined,
        };
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    // print("Starting from {}\n", .{data.start});
    var node: *Node = &data.rows.items[data.start.y].items[data.start.x];
    node.nodeType = data.figureOutStartingPoint();
    var direction = node.nodeType.chooseStartDirection();

    var distance: i64 = 0;
    while (true) {
        distance += 1;
        var nodeWithDirection = data.nextNode(node.location, direction);
        // print("{}->{} because pipe is {}\n", .{ node, nodeWithDirection.node, node.nodeType });
        node = nodeWithDirection.node;
        node.distance = distance;
        direction = nodeWithDirection.direction;
        if (node.location.x == data.start.x and node.location.y == data.start.y) {
            break;
        }
        node.distance = distance;
    }
    return @divTrunc(distance, 2);
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4);
}

test "part 1 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 8);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-10-1.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 6733);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var count: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    // print("Starting from {}\n", .{data.start});
    var node: *Node = &data.rows.items[data.start.y].items[data.start.x];
    node.nodeType = data.figureOutStartingPoint();
    var direction = node.nodeType.chooseStartDirection();

    while (true) {
        var nodeWithDirection = data.nextNode(node.location, direction);
        // print("{}->{} because pipe is {}\n", .{ node, nodeWithDirection.node, node.nodeType });
        node = nodeWithDirection.node;
        direction = nodeWithDirection.direction;
        if (node.location.x == data.start.x and node.location.y == data.start.y) {
            break;
        }
    }
    return count;
}

test "part 2 test 0" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...........
        \\.S-------7.
        \\.|.......|.
        \\.L-------J.
        \\...........
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 7);
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4);
}

test "part 2 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 8);
}

test "part 2 test 3" {
    var list = try util.parseToListOfStrings([]const u8,
        \\FF7FSF7F7F7F7F7F---7
        \\L|LJ||||||||||||F--J
        \\FL-7LJLJ||||||LJL-77
        \\F--JF--7||LJLJ7F7FJ-
        \\L---JF-JLJ.||-FJLJJ7
        \\|F|F-JF---7F7-L7L|7|
        \\|FFJF7L7F-JF7|JL---7
        \\7-L-JL7||F7|L7F-7F7|
        \\L.L7LFJ|||||FJL7||LJ
        \\L7JLJL-JLJLJL--JLJ.L
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 10);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-10-1.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
