const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const SignalPulse = enum {
    High,
    Low,
};

const ComponentType = enum {
    FlipFlop,
    Conjuction,
    Broadcast,
};

const Effect = struct {
    pulse: SignalPulse,
    generation: usize,
};

const Component = struct {
    const Self = @This();
    name: []const u8,
    componentType: ComponentType,
    outputs: std.ArrayList(*Component),
    effects: std.ArrayList(Effect),
    allocator: std.mem.Allocator,
    pulsesHigh: usize,
    pulsesLow: usize,
    // eligible for FlipFlip component type
    value: ?bool = null,
    // eligible for Conjuction
    inputs: ?std.StringHashMap(SignalPulse),

    pub fn init(component: *Component, allocator: std.mem.Allocator, name: []const u8, componentType: ComponentType) !void {
        component.name = try allocator.dupe(u8, name);
        component.componentType = componentType;
        component.outputs = std.ArrayList(*Component).init(allocator);
        component.effects = std.ArrayList(Effect).init(allocator);
        component.value = null;
        component.inputs = null;
        component.allocator = allocator;
        component.pulsesHigh = 0;
        component.pulsesLow = 0;
        switch (componentType) {
            ComponentType.FlipFlop => component.value = false,
            ComponentType.Conjuction => component.inputs = std.StringHashMap(SignalPulse).init(allocator),
            ComponentType.Broadcast => {},
        }
    }

    pub fn registerOutput(self: *Self, output: *Component) !void {
        try self.outputs.append(output);
    }

    pub fn registerInput(self: *Self, input: *Component) !void {
        switch (self.componentType) {
            ComponentType.Conjuction => try self.inputs.?.put(input.name, SignalPulse.Low),
            else => {},
        }
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.name);
        self.outputs.deinit();
        if (self.inputs) |*inputsRaw| {
            inputsRaw.deinit();
        }
        self.effects.deinit();
    }

    pub fn react(self: *Self, pulse: SignalPulse, source: ?Component, generation: usize) !void {
        switch (pulse) {
            SignalPulse.Low => self.pulsesLow += 1,
            SignalPulse.High => self.pulsesHigh += 1,
        }
        // if (source) |sourceRaw| {
        //     print("{s} {}->{s}\n", .{ sourceRaw.name, pulse, self.name });
        // } else {
        //     print("button {}->{s}\n", .{ pulse, self.name });
        // }
        try switch (self.componentType) {
            ComponentType.FlipFlop => self.flipFlop(pulse, generation),
            ComponentType.Conjuction => self.conjuction(pulse, source.?, generation),
            ComponentType.Broadcast => self.broadcast(pulse, generation),
        };
    }

    pub fn processEffects(self: *Self, generation: usize) !void {
        //print("running generation {d} on {s}; effects={any}\n", .{ generation, self.name, self.effects.items });
        for (self.effects.items, 0..) |effect, i| {
            if (effect.generation <= generation) {
                try self.runEffect(effect);
                _ = self.effects.orderedRemove(i);
            }
        }
    }

    fn runEffect(self: *Self, effect: Effect) std.mem.Allocator.Error!void {
        for (self.outputs.items) |*output| {
            try output.*.react(effect.pulse, self.*, effect.generation + 1);
        }
    }

    fn flipFlop(self: *Self, pulse: SignalPulse, generation: usize) !void {
        if (pulse == SignalPulse.High) {
            return;
        }
        self.value = !self.value.?;
        // note: value is already inverted, so is thus the logic
        var effect = Effect{
            .generation = generation + 1,
            .pulse = if (self.value.?) SignalPulse.High else SignalPulse.Low,
        };
        try self.effects.append(effect);
        // if (self.value.?) {
        //     print("\t{s} is now on; size of effects: {any}\n", .{ self.name, self.effects.items });
        // } else {
        //     print("\t{s} is now off; size of effects: {any}\n", .{ self.name, self.effects.items });
        // }
    }

    fn conjuction(self: *Self, pulse: SignalPulse, source: Component, generation: usize) !void {
        var inputs = self.inputs.?;
        try inputs.put(source.name, pulse);
        var highForAll = true;
        var iter = inputs.iterator();
        while (iter.next()) |entry| {
            // print("\tvalue for input {s} is {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
            if (entry.value_ptr.* == SignalPulse.Low) {
                highForAll = false;
            }
        }
        var effect = Effect{
            .generation = generation + 1,
            .pulse = if (highForAll) SignalPulse.Low else SignalPulse.High,
        };
        try self.effects.append(effect);
    }

    fn broadcast(self: *Self, pulse: SignalPulse, generation: usize) !void {
        try self.effects.append(Effect{
            .pulse = pulse,
            .generation = generation + 1,
        });
    }

    pub fn str(self: *Self) void {
        print(", type={}", .{self.componentType});
    }
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    components: std.StringHashMap(*Component),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var components = std.StringHashMap(*Component).init(allocator);
        for (list.items) |line| {
            var iter = std.mem.split(u8, line, " -> ");
            const componentNameAndType = iter.next().?;
            var componentType = ComponentType.Broadcast;
            var name: []const u8 = "broadcaster";
            if (std.mem.startsWith(u8, componentNameAndType, "%")) {
                componentType = ComponentType.FlipFlop;
                name = componentNameAndType[1..];
            } else if (std.mem.startsWith(u8, componentNameAndType, "&")) {
                componentType = ComponentType.Conjuction;
                name = componentNameAndType[1..];
            }
            var component = try allocator.create(Component);
            try component.init(allocator, name, componentType);
            try components.put(name, component);
        }
        for (list.items) |line| {
            var iter = std.mem.split(u8, line, " -> ");
            const componentNameAndType = iter.next().?;
            var name: []const u8 = "broadcaster";
            if (std.mem.startsWith(u8, componentNameAndType, "%")) {
                name = componentNameAndType[1..];
            } else if (std.mem.startsWith(u8, componentNameAndType, "&")) {
                name = componentNameAndType[1..];
            }
            var inputComponent = components.get(name).?;
            var componentOutputs = std.mem.split(u8, iter.next().?, ", ");
            while (componentOutputs.next()) |output| {
                var outputComponent = components.get(output).?;
                try inputComponent.registerOutput(outputComponent);
                try outputComponent.registerInput(inputComponent);
            }
        }
        return Self{
            .components = components,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        var keyIter = self.components.keyIterator();
        while (keyIter.next()) |key| {
            var component = self.components.get(key.*).?;
            component.*.deinit();
            self.allocator.destroy(component);
        }
        self.components.deinit();
    }

    pub fn debug(components: std.StringHashMap(*Component)) !void {
        print("Debugging data\n", .{});
        var iter = components.iterator();
        while (iter.next()) |entry| {
            print("{s} -> ", .{entry.key_ptr.*});
            if (entry.value_ptr.*.inputs) |inputsRaw| {
                print("size of inputs: {d}", .{inputsRaw.count()});
            }
            entry.value_ptr.*.str();
            print("\n", .{});
        }
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    // try Data.debug(data.components);

    var broadcaster = data.components.get("broadcaster").?;
    for (0..1000) |_| {
        var generation: usize = 0;
        try broadcaster.react(SignalPulse.Low, null, generation);
        while (true) : (generation += 1) {
            var valueIter = data.components.valueIterator();
            while (valueIter.next()) |component| {
                try component.*.processEffects(generation);
            }
            var hasStillSomeEffects = false;
            valueIter = data.components.valueIterator();
            while (valueIter.next()) |component| {
                hasStillSomeEffects = hasStillSomeEffects or (component.*.effects.items.len > 0);
            }
            if (!hasStillSomeEffects) {
                break;
            }
        }
    }

    var pulsesHigh: usize = 0;
    var pulsesLow: usize = 0;
    var valueIter = data.components.valueIterator();
    while (valueIter.next()) |component| {
        pulsesHigh += component.*.pulsesHigh;
        pulsesLow += component.*.pulsesLow;
    }

    return pulsesHigh * pulsesLow;
}

test "map operations in zig" {
    var allocator = std.testing.allocator;
    var components = std.StringHashMap(*Component).init(allocator);
    var c = try Component.init(allocator, "123", ComponentType.FlipFlop);
    c.inputs = std.StringHashMap(SignalPulse).init(allocator);
    try components.put("123", &c);
    try components.get("123").?.inputs.?.put("123", SignalPulse.High);
    try std.testing.expectEqual(components.get("123").?.inputs.?.get("123").?, SignalPulse.High);
    try components.get("123").?.inputs.?.put("123", SignalPulse.Low);
    try std.testing.expectEqual(components.get("123").?.inputs.?.get("123").?, SignalPulse.Low);
    var iter1 = components.iterator();
    while (iter1.next()) |entry| {
        print("{s} -> ", .{entry.key_ptr.*});
        if (entry.value_ptr.*.inputs) |inputsRaw| {
            print("size of inputs: {d}", .{inputsRaw.count()});
        }
        entry.value_ptr.*.str();
        print("\n", .{});
    }
    // cleanup
    var iter = components.iterator();
    while (iter.next()) |i| {
        i.value_ptr.*.deinit();
    }
    defer components.deinit();
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\broadcaster -> a, b, c
        \\%a -> b
        \\%b -> c
        \\%c -> inv
        \\&inv -> a
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 32000000);
}

test "part 1 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\broadcaster -> a
        \\%a -> inv, con
        \\&inv -> b
        \\%b -> con
        \\&con -> output
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 11687500);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-20.txt");
    defer data.deinit();

    const testValue: usize = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var sum: usize = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    // access input data...
    // for (data.rows.items) |rowData| {

    // }

    return sum;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\broadcaster -> a, b, c
        \\%a -> b
        \\%b -> c
        \\%c -> inv
        \\&inv -> a
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 32000000);
}

test "part 2 test 2" {
    var list = try util.parseToListOfStrings([]const u8,
        \\broadcaster -> a
        \\%a -> inv, con
        \\&inv -> b
        \\%b -> con
        \\&con -> output
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 11687500);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-20.txt");
    defer data.deinit();

    const testValue: usize = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
