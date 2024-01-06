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

const Component = struct {
    const Self = @This();
    name: []const u8,
    componentType: ComponentType,
    outputs: std.ArrayList(*Component),
    effects: std.ArrayList(SignalPulse),
    allocator: std.mem.Allocator,
    // eligible for FlipFlip component type
    value: ?bool = null,
    // eligible for Conjuction
    inputs: ?std.StringHashMap(SignalPulse),

    pub fn init(component: *Component, allocator: std.mem.Allocator, name: []const u8, componentType: ComponentType) !void {
        component.name = try allocator.dupe(u8, name);
        component.componentType = componentType;
        component.outputs = std.ArrayList(*Component).init(allocator);
        component.effects = std.ArrayList(SignalPulse).init(allocator);
        component.value = null;
        component.inputs = null;
        component.allocator = allocator;
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

    pub fn react(self: *Self, pulse: SignalPulse, source: ?Component) !void {
        if (source) |sourceRaw| {
            print("{s} {}->{s}\n", .{ sourceRaw.name, pulse, self.name });
        } else {
            print("button {}->{s}\n", .{ pulse, self.name });
        }
        try switch (self.componentType) {
            ComponentType.FlipFlop => self.flipFlop(pulse),
            ComponentType.Conjuction => self.conjuction(pulse, source.?),
            ComponentType.Broadcast => self.broadcast(pulse),
        };
    }

    pub fn processEffects(self: *Self) !void {
        for (self.effects.items) |effect| {
            try self.runEffect(effect);
        }
        self.effects.clearAndFree();
    }

    fn runEffect(self: *Self, effect: SignalPulse) std.mem.Allocator.Error!void {
        for (self.outputs.items) |*output| {
            try output.*.react(effect, self.*);
        }
        for (self.outputs.items) |*output| {
            try output.*.processEffects();
        }
    }

    fn flipFlop(self: *Self, pulse: SignalPulse) !void {
        if (pulse == SignalPulse.High) {
            return;
        }
        self.value = !self.value.?;
        if (self.value.?) {
            print("\t{s} is now on; size of effects: {d}\n", .{ self.name, self.effects.items.len });
        } else {
            print("\t{s} is now off; size of effects: {d}\n", .{ self.name, self.effects.items.len });
        }
        // note: value is already inverted, so is thus the logic
        try self.effects.append(if (self.value.?) SignalPulse.High else SignalPulse.Low);
    }

    fn conjuction(self: *Self, pulse: SignalPulse, source: Component) !void {
        var inputs = self.inputs.?;
        try inputs.put(source.name, pulse);
        var highForAll = true;
        var iter = inputs.iterator();
        while (iter.next()) |entry| {
            print("\tvalue for input {s} is {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
            if (entry.value_ptr.* == SignalPulse.Low) {
                highForAll = false;
            }
        }
        if (highForAll) {
            try self.effects.append(SignalPulse.Low);
        } else {
            try self.effects.append(SignalPulse.High);
        }
    }

    fn broadcast(self: *Self, pulse: SignalPulse) !void {
        try self.effects.append(pulse);
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

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var sum: i64 = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    // try Data.debug(data.components);

    var broadcaster = data.components.get("broadcaster").?;
    try broadcaster.react(SignalPulse.Low, null);
    try broadcaster.processEffects();

    return sum;
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

    const testValue: i64 = try part1(std.testing.allocator, list);
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

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 11687500);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-20.txt");
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
        \\broadcaster -> a, b, c
        \\%a -> b
        \\%b -> c
        \\%c -> inv
        \\&inv -> a
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
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

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 11687500);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-20.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, -1);
}
