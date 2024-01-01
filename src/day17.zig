const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    rows: std.ArrayList(std.ArrayList(u8)),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var rows: std.ArrayList(std.ArrayList(u8)) = std.ArrayList(std.ArrayList(u8)).init(allocator);
        for (list.items) |line| {
            // print("line={s}\n", .{line});
            var row = std.ArrayList(u8).init(allocator);
            for (line) |block| {
                try row.append(block - '0');
            }
            try rows.append(row);
        }
        return Self{
            .allocator = allocator,
            .rows = rows,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.rows.items) |row| {
            row.deinit();
        }
        self.rows.deinit();
    }

    pub fn printMap(self: *Self, dist: std.AutoHashMap(u64, BackTrack), minDistance: FinalDistance) !void {
        var nodesOnPath = std.AutoHashMap(u64, void).init(self.allocator);
        defer nodesOnPath.deinit();
        var iterPath: NeighborCandidate = minDistance.neighbor.?;
        while (true) {
            try nodesOnPath.put(util.hasher2(iterPath.neighbor.x, iterPath.neighbor.y), {});
            // print("coord={d}/{d} ({d})\n", .{
            //     iterPath.neighbor.x,
            //     iterPath.neighbor.y,
            //     self.rows.items[iterPath.neighbor.y].items[iterPath.neighbor.x],
            // });
            var d: BackTrack = dist.get(iterPath.hash()).?;
            if (iterPath.neighbor.x == 0 and iterPath.neighbor.y == 0) {
                break;
            } else {
                iterPath = d.previous.?;
            }
            if (nodesOnPath.contains(util.hasher2(iterPath.neighbor.x, iterPath.neighbor.y))) {
                std.debug.print("LOOP found, escaping", .{});
                break;
            }
        }
        print("\n", .{});
        for (self.rows.items, 0..) |row, y| {
            for (row.items, 0..) |ch, x| {
                if (nodesOnPath.contains(util.hasher2(@truncate(x), @truncate(y)))) {
                    print("*", .{});
                } else {
                    print("{d}", .{ch});
                }
            }
            print("\n", .{});
        }
    }

    fn getNeighbors(self: *Self, nodeSource: QueueCandidate, maxX: usize, maxY: usize) !std.ArrayList(NeighborCandidate) {
        var neighbors = try std.ArrayList(NeighborCandidate).initCapacity(self.allocator, 4);
        const node = nodeSource.neighbor;
        const allowedStepsInDirection = 3;
        // we need to:
        // 1. block return path
        // 2. block more than 3 steps in a row in the same direction
        if (node.y > 0 and nodeSource.direction != Direction.Down and (nodeSource.direction != Direction.Up or nodeSource.stepInDirection < allowedStepsInDirection)) {
            try neighbors.append(NeighborCandidate{
                .direction = Direction.Up,
                .stepInDirection = if (nodeSource.direction == Direction.Up) nodeSource.stepInDirection + 1 else 1,
                .weight = self.rows.items[node.y - 1].items[node.x],
                .neighbor = Node{
                    .x = node.x,
                    .y = node.y - 1,
                },
            });
        }
        if (node.x > 0 and nodeSource.direction != Direction.Right and (nodeSource.direction != Direction.Left or nodeSource.stepInDirection < allowedStepsInDirection)) {
            try neighbors.append(NeighborCandidate{
                .direction = Direction.Left,
                .stepInDirection = if (nodeSource.direction == Direction.Left) nodeSource.stepInDirection + 1 else 1,
                .weight = self.rows.items[node.y].items[node.x - 1],
                .neighbor = Node{
                    .x = node.x - 1,
                    .y = node.y,
                },
            });
        }
        if (node.y < maxY and nodeSource.direction != Direction.Up and (nodeSource.direction != Direction.Down or nodeSource.stepInDirection < allowedStepsInDirection)) {
            try neighbors.append(NeighborCandidate{
                .direction = Direction.Down,
                .stepInDirection = if (nodeSource.direction == Direction.Down) nodeSource.stepInDirection + 1 else 1,
                .weight = self.rows.items[node.y + 1].items[node.x],
                .neighbor = Node{
                    .x = node.x,
                    .y = node.y + 1,
                },
            });
        }
        if (node.x < maxX and nodeSource.direction != Direction.Left and (nodeSource.direction != Direction.Right or nodeSource.stepInDirection < allowedStepsInDirection)) {
            try neighbors.append(NeighborCandidate{
                .direction = Direction.Right,
                .stepInDirection = if (nodeSource.direction == Direction.Right) nodeSource.stepInDirection + 1 else 1,
                .weight = self.rows.items[node.y].items[node.x + 1],
                .neighbor = Node{
                    .x = node.x + 1,
                    .y = node.y,
                },
            });
        }
        return neighbors;
    }
};

const Node = struct {
    x: u8,
    y: u8,
};

const NeighborCandidate = struct {
    neighbor: Node,
    weight: u16 = 0,
    direction: Direction,
    stepInDirection: u8,

    fn hash(self: NeighborCandidate) u64 {
        return util.hasher4(self.neighbor.x, self.neighbor.y, @intFromEnum(self.direction), self.stepInDirection);
    }
};

const QueueCandidate = struct {
    neighbor: Node,
    distance: u16 = 0,
    direction: Direction,
    stepInDirection: u8,
};

const Direction = enum { Down, Up, Right, Left };

const FinalDistance = struct {
    distance: i64,
    neighbor: ?NeighborCandidate,
};

const BackTrack = struct {
    distance: i64,
    previous: ?NeighborCandidate = null,
};

fn lessThan(context: void, a: QueueCandidate, b: QueueCandidate) std.math.Order {
    _ = context;
    return std.math.order(a.distance, b.distance);
}

// Based on priority-queue Dijkstra variant
// import heapq
// def dijkstra(graph, start):
//     # Priority queue to store (distance, node) pairs
//     priority_queue = [(0, start)]
//
//     # Dictionary to store the distance from the start node to each node
//     distances = {node: float('infinity') for node in graph}
//     distances[start] = 0
//
//     while priority_queue:
//         current_distance, current_node = heapq.heappop(priority_queue)
//
//         # Check if the current distance is greater than the known distance
//         if current_distance > distances[current_node]:
//             continue
//
//         # Explore neighbors of the current node
//         for neighbor, weight in graph[current_node].items():
//             distance = current_distance + weight
//
//             # If a shorter path is found, update the distance and add to the priority queue
//             if distance < distances[neighbor]:
//                 distances[neighbor] = distance
//                 heapq.heappush(priority_queue, (distance, neighbor))
//
//     return distances
//
// graph = {
//     'A': {'B': 1, 'C': 4},
//     'B': {'A': 1, 'C': 2, 'D': 5},
//     'C': {'A': 4, 'B': 2, 'D': 1},
//     'D': {'B': 5, 'C': 1}
// }
//
// start_node = 'A'
// result = dijkstra(graph, start_node)
//
// print(f"Shortest distances from {start_node}: {result}")
pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    var queue = std.PriorityQueue(QueueCandidate, void, lessThan).init(allocator, {});
    defer queue.deinit();

    try queue.add(QueueCandidate{
        .distance = data.rows.items[0].items[1],
        .neighbor = Node{
            .x = 1,
            .y = 0,
        },
        .direction = Direction.Right,
        .stepInDirection = 1,
    });
    try queue.add(QueueCandidate{
        .distance = data.rows.items[1].items[0],
        .neighbor = Node{
            .x = 0,
            .y = 1,
        },
        .direction = Direction.Down,
        .stepInDirection = 1,
    });

    var dist = std.AutoHashMap(u64, BackTrack).init(allocator);
    defer dist.deinit();

    // add 2 possible start states and mark them as zero-distance
    try dist.put(util.hasher5(0, 0, 0, @intFromEnum(Direction.Down), 0), BackTrack{
        .previous = null,
        .distance = 0,
    });
    try dist.put(util.hasher5(0, 0, 0, @intFromEnum(Direction.Right), 0), BackTrack{
        .previous = null,
        .distance = 0,
    });

    const maxX: u8 = @truncate(data.rows.items[0].items.len - 1);
    const maxY: u8 = @truncate(data.rows.items.len - 1);

    var minDistance: FinalDistance = FinalDistance{
        .distance = std.math.maxInt(i64),
        .neighbor = null,
    };

    while (queue.len > 0) {
        const d = queue.remove();
        const currentDistance = d.distance;
        if (currentDistance > minDistance.distance) {
            continue;
        }
        const neighbors = try data.getNeighbors(d, maxX, maxY);
        defer neighbors.deinit();

        for (neighbors.items) |neighborDistance| {
            const neighbor = neighborDistance.neighbor;
            const distance = currentDistance + neighborDistance.weight;
            var candidate = dist.get(neighborDistance.hash());
            if (candidate == null or distance < candidate.?.distance) {
                // std.debug.print("Shortest on {} is to {} [neighbor.direction={}, stepInDirection={d}] (current={d} + neighbor.weight={d} => distance={d})\n", .{
                //     d.neighbor,
                //     neighborDistance.neighbor,
                //     neighborDistance.direction,
                //     neighborDistance.stepInDirection,
                //     currentDistance,
                //     neighborDistance.weight,
                //     distance,
                // });
                try dist.put(neighborDistance.hash(), BackTrack{
                    .distance = distance,
                    .previous = NeighborCandidate{
                        .weight = d.distance,
                        .neighbor = Node{
                            .x = d.neighbor.x,
                            .y = d.neighbor.y,
                        },
                        .direction = d.direction,
                        .stepInDirection = d.stepInDirection,
                    },
                });
                try queue.add(QueueCandidate{
                    .distance = distance,
                    .neighbor = Node{
                        .x = neighbor.x,
                        .y = neighbor.y,
                    },
                    .direction = neighborDistance.direction,
                    .stepInDirection = neighborDistance.stepInDirection,
                });
                if (neighbor.x == maxX and neighbor.y == maxY and minDistance.distance > distance) {
                    minDistance = FinalDistance{
                        .neighbor = neighborDistance,
                        .distance = distance,
                    };
                }
            }
        }
    }

    try data.printMap(dist, minDistance);

    return minDistance.distance;
}

test "part 1 test 0.1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\119999
        \\951111
        \\999991
        \\999991
        \\999991
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 17);
}

test "part 1 test 0.2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\14999
        \\23111
        \\99991
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 11);
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 102);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-17.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    // 725 is too high
    try std.testing.expectEqual(testValue, -1);
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
    var data = try util.openFile(std.testing.allocator, "data/input-N.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
