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

    pub fn printMap(self: *Self, dist: std.AutoHashMap(u64, TotalDistance)) !void {
        var nodesOnPath = std.AutoHashMap(u64, void).init(self.allocator);
        defer nodesOnPath.deinit();
        const maxX: u8 = @truncate(self.rows.items[0].items.len - 1);
        const maxY: u8 = @truncate(self.rows.items.len - 1);
        var iterPath = Node{
            .x = maxX,
            .y = maxY,
        };
        while (true) {
            try nodesOnPath.put(util.hasher(iterPath.x, iterPath.y), {});
            // print("coord={d}/{d} ({d})\n", .{ iterPath.x, iterPath.y, data.rows.items[iterPath.y].items[iterPath.x] });
            var d = dist.get(util.hasher(iterPath.x, iterPath.y)).?;
            if (d.previousInPath) |previous| {
                iterPath = previous;
            } else {
                break;
            }
        }
        print("\n", .{});
        for (self.rows.items, 0..) |row, y| {
            for (row.items, 0..) |ch, x| {
                if (nodesOnPath.contains(util.hasher(@truncate(x), @truncate(y)))) {
                    print("*", .{});
                } else {
                    print("{d}", .{ch});
                }
            }
            print("\n", .{});
        }
    }
};

const Node = struct {
    x: u8,
    y: u8,
};

const NodeDistance = struct {
    distance: i64,
    neighbor: Node,
};

const TotalDistance = struct {
    distance: i64,
    previousInPath: ?Node,
};

fn lessThan(context: void, a: NodeDistance, b: NodeDistance) std.math.Order {
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

    var queue = std.PriorityQueue(NodeDistance, void, lessThan).init(allocator, {});
    defer queue.deinit();

    try queue.add(NodeDistance{ .distance = 0, .neighbor = Node{
        .x = 0,
        .y = 0,
    } });

    var dist = std.AutoHashMap(u64, TotalDistance).init(allocator);
    defer dist.deinit();

    for (data.rows.items, 0..) |row, y| {
        for (row.items, 0..) |_, x| {
            try dist.put(util.hasher(@truncate(x), @truncate(y)), TotalDistance{
                .distance = std.math.maxInt(i64),
                .previousInPath = null,
            });
        }
    }
    try dist.put(util.hasher(0, 0), TotalDistance{
        .distance = 0,
        .previousInPath = null,
    });

    const maxX: u8 = @truncate(data.rows.items[0].items.len - 1);
    const maxY: u8 = @truncate(data.rows.items.len - 1);

    while (queue.len > 0) {
        const d = queue.remove();
        const currentNode = d.neighbor;
        const currentDistance = d.distance;
        if (currentDistance > dist.get(util.hasher(currentNode.x, currentNode.y)).?.distance) {
            continue;
        }
        const neighbors = try getNeighbors(allocator, currentNode, maxX, maxY);
        defer neighbors.deinit();

        for (neighbors.items) |neighbor| {
            const weight = data.rows.items[neighbor.y].items[neighbor.x];
            const distance = currentDistance + weight;
            if (distance < dist.get(util.hasher(neighbor.x, neighbor.y)).?.distance) {
                try dist.put(util.hasher(neighbor.x, neighbor.y), TotalDistance{
                    .distance = distance,
                    .previousInPath = currentNode,
                });
                try queue.add(NodeDistance{ .distance = distance, .neighbor = Node{
                    .x = neighbor.x,
                    .y = neighbor.y,
                } });
            }
        }
    }

    try data.printMap(dist);

    return dist.get(util.hasher(maxX, maxY)).?.distance;
}

fn getNeighbors(allocator: std.mem.Allocator, node: Node, maxX: usize, maxY: usize) !std.ArrayList(Node) {
    var neighbors = try std.ArrayList(Node).initCapacity(allocator, 3);
    if (node.y > 0) {
        try neighbors.append(Node{
            .x = node.x,
            .y = node.y - 1,
        });
    }
    if (node.y < maxY) {
        try neighbors.append(Node{
            .x = node.x,
            .y = node.y + 1,
        });
    }
    if (node.x < maxX) {
        try neighbors.append(Node{
            .x = node.x + 1,
            .y = node.y,
        });
    }
    return neighbors;
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
