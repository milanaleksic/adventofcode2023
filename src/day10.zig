const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Direction = enum {
    North,
    West,
    South,
    East,

    pub fn reverse(self: Direction) Direction {
        return switch (self) {
            Direction.North => Direction.South,
            Direction.South => Direction.North,
            Direction.West => Direction.East,
            Direction.East => Direction.West,
        };
    }
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

    pub fn toPathChar(self: NodeType) u16 {
        return switch (self) {
            NodeType.NS => '|',
            NodeType.WE => '-',
            NodeType.NE => '└',
            NodeType.NW => '┘',
            NodeType.SW => '┐',
            NodeType.SE => '┌',
            else => '!',
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

    pub fn matchOppositeSide(self: NodeType, incomingDirection: Direction) ?Direction {
        return switch (self) {
            NodeType.NW => if (incomingDirection == Direction.North) Direction.West else if (incomingDirection == Direction.West) Direction.North else null,
            NodeType.NS => if (incomingDirection == Direction.North) Direction.South else if (incomingDirection == Direction.South) Direction.North else null,
            NodeType.WE => if (incomingDirection == Direction.East) Direction.West else if (incomingDirection == Direction.West) Direction.East else null,
            NodeType.NE => if (incomingDirection == Direction.North) Direction.East else if (incomingDirection == Direction.East) Direction.North else null,
            NodeType.SW => if (incomingDirection == Direction.South) Direction.West else if (incomingDirection == Direction.West) Direction.South else null,
            NodeType.SE => if (incomingDirection == Direction.South) Direction.East else if (incomingDirection == Direction.East) Direction.South else null,
            else => return null,
        };
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
    location: Loc,
    // relevant for path 2
    partOfPath: bool,
    escapes: ?bool,
    underInvestigation: bool,
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
                    .location = loc,
                    .partOfPath = false,
                    .escapes = null,
                    .underInvestigation = false,
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

    pub fn nextNode(self: *Self, loc: Loc, incomingDirection: Direction) ?NodeWithDirection {
        const node = self.rows.items[loc.y].items[loc.x];
        // print("Approaching {} from {}\n", .{ node, incomingDirection });
        if (node.nodeType.matchOppositeSide(incomingDirection)) |opposite| {
            if (self.goTo(loc, opposite)) |nl| {
                return NodeWithDirection{
                    .node = nl,
                    .direction = opposite.reverse(),
                };
            }
        }
        return null;
    }

    pub fn goTo(self: *Self, loc: Loc, directionToMove: Direction) ?*Node {
        return switch (directionToMove) {
            Direction.North => if (loc.y > 0) &self.rows.items[loc.y - 1].items[loc.x] else null,
            Direction.South => if (loc.y < self.rows.items.len - 1) &self.rows.items[loc.y + 1].items[loc.x] else null,
            Direction.West => if (loc.x > 0) &self.rows.items[loc.y].items[loc.x - 1] else null,
            Direction.East => if (loc.x < self.rows.items[0].items.len - 1) &self.rows.items[loc.y].items[loc.x + 1] else null,
        };
    }

    pub fn printMap(self: *Self) void {
        print("\n", .{});
        for (self.rows.items) |row| {
            for (row.items) |cell| {
                if (cell.partOfPath) {
                    print("{u}", .{cell.nodeType.toPathChar()});
                    continue;
                } else if (cell.escapes) |escapes| {
                    switch (escapes) {
                        true => print("O", .{}),
                        false => print("I", .{}),
                    }
                    continue;
                } else {
                    print("?", .{});
                }
            }
            print("\n", .{});
        }
    }
};

const Side = enum {
    Left,
    Right,
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
        node = nodeWithDirection.?.node;
        direction = nodeWithDirection.?.direction;
        if (node.location.x == data.start.x and node.location.y == data.start.y) {
            break;
        }
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
    var data = try util.openFile(std.testing.allocator, "data/input-10.txt");
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
    node.partOfPath = true;
    var direction = node.nodeType.chooseStartDirection();

    while (true) {
        var nodeWithDirection = data.nextNode(node.location, direction);
        // print("{}->{} because pipe is {}\n", .{ node, nodeWithDirection.node, node.nodeType });
        node = nodeWithDirection.?.node;
        direction = nodeWithDirection.?.direction;
        if (node.location.x == data.start.x and node.location.y == data.start.y) {
            break;
        }
        node.partOfPath = true;
    }

    // data.printMap();

    // var maxPercent: usize = 0;
    for (data.rows.items, 0..) |row, i| {
        _ = i;
        for (row.items, 0..) |*cell, y| {
            _ = y;
            // var P = data.rows.items[0].items.len * i + y;
            // var G = data.rows.items.len * data.rows.items[0].items.len;
            // var percent = 100 * P / G;
            // if (percent > maxPercent) {
            //     print("Reached {d}%\n", .{percent});
            //     maxPercent = percent;
            // }
            if (cell.partOfPath) {
                continue;
            }
            if (cell.escapes) |_| {
                continue;
            }
            _ = investigate(&data, cell);
        }
    }

    // data.printMap();

    for (data.rows.items) |row| {
        for (row.items) |cell| {
            if (!cell.partOfPath and cell.escapes == null) {
                count += 1;
            }
        }
    }

    return count;
}

fn nodeIsGroundOnBorder(data: *Data, node: *Node) bool {
    if (node.nodeType == NodeType.GROUND) {
        return node.location.x == 0 or node.location.y == 0 or node.location.y == data.rows.items.len - 1 or node.location.x == data.rows.items[0].items.len - 1;
    }
    return false;
}

fn checkIfNodeEscapes(data: *Data, node: *Node, incomingDirection: Direction) bool {
    if (incomingDirection == Direction.East) {
        if (node.nodeType == NodeType.SW and followTubeToExit(data, node, Direction.South, Side.Right)) {
            return true;
        } else if (node.nodeType == NodeType.NW and followTubeToExit(data, node, Direction.North, Side.Left)) {
            return true;
        }
    } else if (incomingDirection == Direction.West) {
        if (node.nodeType == NodeType.SE and followTubeToExit(data, node, Direction.South, Side.Left)) {
            return true;
        } else if (node.nodeType == NodeType.NE and followTubeToExit(data, node, Direction.North, Side.Right)) {
            return true;
        }
    } else if (incomingDirection == Direction.North) {
        if (node.nodeType == NodeType.SE and followTubeToExit(data, node, Direction.East, Side.Right)) {
            return true;
        } else if (node.nodeType == NodeType.SW and followTubeToExit(data, node, Direction.West, Side.Left)) {
            return true;
        }
    } else if (incomingDirection == Direction.South) {
        if (node.nodeType == NodeType.NE and followTubeToExit(data, node, Direction.East, Side.Left)) {
            return true;
        } else if (node.nodeType == NodeType.NW and followTubeToExit(data, node, Direction.West, Side.Right)) {
            return true;
        }
    }
    return false;
}

fn overReachingEscapes(data: *Data, node: *Node, direction: Direction) bool {
    if (data.goTo(node.location, direction)) |overReachingRaw| {
        if (overReachingRaw.escapes) |_| {
            return true;
        }
        if (nodeIsGroundOnBorder(data, overReachingRaw)) {
            // print("overreaching to ground found at the location {}\n", .{overReachingRaw});
            return true;
        }
    }
    return false;
}

fn followTubeToExit(data: *Data, node: *Node, incomingDirection: Direction, side: Side) bool {
    const startLoc = node;
    var nodeIter = node;
    var directionIter = incomingDirection;
    while (true) {
        // print("follow tube to: {}\n", .{nodeIter.location});
        var nodeWithDirectionOptional = data.nextNode(nodeIter.location, directionIter);
        if (nodeWithDirectionOptional) |nodeWithDirection| {
            // if (nodeWithDirection.node.escapes) |_| {
            //     return true;
            // }
            if (nodeWithDirection.node.nodeType == NodeType.NW) {
                if (nodeWithDirection.direction == Direction.North and overReachingEscapes(data, nodeWithDirection.node, Direction.South)) {
                    return side == Side.Left;
                } else if (nodeWithDirection.direction == Direction.West and overReachingEscapes(data, nodeWithDirection.node, Direction.East)) {
                    return side == Side.Right;
                }
            } else if (nodeWithDirection.node.nodeType == NodeType.SW) {
                if (nodeWithDirection.direction == Direction.South and overReachingEscapes(data, nodeWithDirection.node, Direction.North)) {
                    return side == Side.Right;
                } else if (nodeWithDirection.direction == Direction.West and overReachingEscapes(data, nodeWithDirection.node, Direction.East)) {
                    return side == Side.Left;
                }
            } else if (nodeWithDirection.node.nodeType == NodeType.NE) {
                if (nodeWithDirection.direction == Direction.North and overReachingEscapes(data, nodeWithDirection.node, Direction.South)) {
                    return side == Side.Right;
                } else if (nodeWithDirection.direction == Direction.East and overReachingEscapes(data, nodeWithDirection.node, Direction.West)) {
                    return side == Side.Left;
                }
            } else if (nodeWithDirection.node.nodeType == NodeType.SE) {
                if (nodeWithDirection.direction == Direction.South and overReachingEscapes(data, nodeWithDirection.node, Direction.North)) {
                    return side == Side.Left;
                } else if (nodeWithDirection.direction == Direction.East and overReachingEscapes(data, nodeWithDirection.node, Direction.West)) {
                    return side == Side.Right;
                }
            }

            directionIter = nodeWithDirection.direction;
            nodeIter = nodeWithDirection.node;
            if (nodeIter.location.x == startLoc.location.x and nodeIter.location.y == startLoc.location.y) {
                break;
            }
        } else {
            return false;
        }
    }
    return false;
}

fn investigate(data: *Data, node: *Node) void {
    if (node.underInvestigation or node.partOfPath) {
        return;
    }
    if (nodeIsGroundOnBorder(data, node)) {
        node.escapes = true;
    }
    node.underInvestigation = true;
    visit(data, node, Direction.South);
    visit(data, node, Direction.West);
    visit(data, node, Direction.East);
    visit(data, node, Direction.North);
    // node.underInvestigation = false;
}

fn visit(data: *Data, node: *Node, direction: Direction) void {
    if (data.goTo(node.location, direction)) |n| {
        investigate(data, n);
        if (n.escapes) |escapes| {
            node.escapes = escapes;
        } else if (checkIfNodeEscapes(data, n, direction.reverse())) {
            node.escapes = true;
        }
    }
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...........
        \\.S-------7.
        \\.|.......|.
        \\.L-------J.
        \\...........
        \\...........
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 7);
}

test "part 2 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\...........
        \\.S-------7.
        \\.|.......|.
        \\.|..F-7..|.
        \\.L--J.L--J.
        \\...........
        \\...........
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 11);
}

test "part 2 test 3" {
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

test "part 2 test 4" {
    var list = try util.parseToListOfStrings([]const u8,
        \\..........
        \\.S------7.
        \\.|F----7|.
        \\.||....||.
        \\.||....||.
        \\.|L-7F-J|.
        \\.|..||..|.
        \\.L--JL--J.
        \\..........
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4);
}

test "part 2 test 5" {
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

test "part 2 test 6" {
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
    var data = try util.openFile(std.testing.allocator, "data/input-10.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 435);
}
