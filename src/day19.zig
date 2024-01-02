const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const OutcomeType = enum {
    Accept,
    Reject,
    MoveToAnotherWorkflow,
};

const Outcome = struct {
    outcomeType: OutcomeType,
    // in case of outcomeType == OutcomeType.MoveToAnotherWorkflow
    targetWorkflowName: ?[]const u8 = null,
};

const Feature = enum {
    ExtremelyCoolLooking,
    Musical,
    Aerodynamic,
    Shiny,
};

const Operation = enum {
    const Self = @This();
    LessThan,
    GreaterThan,

    pub fn op(self: Self, value: usize, other: usize) bool {
        return switch (self) {
            Operation.LessThan => value < other,
            Operation.GreaterThan => value > other,
        };
    }
};

const Evaluation = struct {
    const Self = @This();
    // optional: sometimes Evaluation is a constant outcome
    feature: ?Feature = null,
    operation: ?Operation = null,
    value: ?usize = null,
    outcome: Outcome,

    pub fn evaluate(self: Self, item: Item) ?Outcome {
        if (self.feature) |featureRaw| {
            const eligible = switch (featureRaw) {
                Feature.Aerodynamic => self.operation.?.op(item.aerodynamic.?, self.value.?),
                Feature.ExtremelyCoolLooking => self.operation.?.op(item.extremelyCoolLooking.?, self.value.?),
                Feature.Musical => self.operation.?.op(item.musical.?, self.value.?),
                Feature.Shiny => self.operation.?.op(item.shiny.?, self.value.?),
            };
            if (eligible) {
                return self.outcome;
            }
        } else {
            return self.outcome;
        }
        return null;
    }
};

const Workflow = struct {
    const Self = @This();
    name: []const u8,
    evaluations: std.ArrayList(Evaluation),

    pub fn evaluate(self: *Self, item: Item) Outcome {
        for (self.evaluations.items) |evaluation| {
            if (evaluation.evaluate(item)) |outcome| {
                return outcome;
            }
        }
        @panic("unexpected state: no outcome reached");
    }
};

const Item = struct {
    extremelyCoolLooking: ?usize = null,
    musical: ?usize = null,
    aerodynamic: ?usize = null,
    shiny: ?usize = null,

    pub fn featureSum(item: Item) usize {
        var sum: usize = 0;
        sum += item.aerodynamic orelse 0;
        sum += item.extremelyCoolLooking orelse 0;
        sum += item.musical orelse 0;
        sum += item.shiny orelse 0;
        return sum;
    }
};

const Data = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    workflows: std.StringHashMap(Workflow),
    items: std.ArrayList(Item),

    pub fn init(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !Self {
        var workflows = std.StringHashMap(Workflow).init(allocator);
        var items = std.ArrayList(Item).init(allocator);

        var modeWorkflows = true;
        for (list.items) |line| {
            if (line.len == 0) {
                modeWorkflows = false;
                continue;
            }
            if (modeWorkflows) {
                const workflow = try parseWorkflow(allocator, line);
                try workflows.put(workflow.name, workflow);
            } else {
                try items.append(try parseItem(line));
            }
        }
        return Self{
            .workflows = workflows,
            .items = items,
            .allocator = allocator,
        };
    }

    fn parseWorkflow(allocator: std.mem.Allocator, line: []const u8) !Workflow {
        const endOfName = std.mem.indexOf(u8, line, "{").?;
        const workflowName = line[0..endOfName];
        // std.debug.print("Parsing workflow {s}\n", .{workflowName});

        var evaluations = std.ArrayList(Evaluation).init(allocator);
        const evaluationString = line[endOfName + 1 .. line.len - 1];
        // std.debug.print("Evaluating command {s}\n", .{evaluationString});
        var commandSplits = std.mem.split(u8, evaluationString, ",");
        while (commandSplits.next()) |split| {
            if (std.mem.indexOf(u8, split, ":")) |designatorChar| {
                var ingress = split[designatorChar + 1 ..];
                var evaluation = parseEvaluation(ingress);

                var workflowEvaluation = split[0..designatorChar];
                if (workflowEvaluation[1] == '>') {
                    evaluation.operation = Operation.GreaterThan;
                    evaluation.value = try util.toUsize(workflowEvaluation[2..]);
                    evaluation.feature = parseFeature(workflowEvaluation[0]);
                } else if (workflowEvaluation[1] == '<') {
                    evaluation.operation = Operation.LessThan;
                    evaluation.value = try util.toUsize(workflowEvaluation[2..]);
                    evaluation.feature = parseFeature(workflowEvaluation[0]);
                } else {
                    @panic("unknown operation detected");
                }
                try evaluations.append(evaluation);
            } else {
                try evaluations.append(parseEvaluation(split));
            }
        }

        return Workflow{
            .name = workflowName,
            .evaluations = evaluations,
        };
    }

    fn parseFeature(ch: u8) Feature {
        return switch (ch) {
            'x' => Feature.ExtremelyCoolLooking,
            'm' => Feature.Musical,
            'a' => Feature.Aerodynamic,
            's' => Feature.Shiny,
            else => @panic("unknown feature type detected"),
        };
    }

    fn parseEvaluation(evaluationString: []const u8) Evaluation {
        if (std.mem.eql(u8, evaluationString, "A")) {
            return Evaluation{ .outcome = Outcome{ .outcomeType = OutcomeType.Accept } };
        } else if (std.mem.eql(u8, evaluationString, "R")) {
            return Evaluation{ .outcome = Outcome{ .outcomeType = OutcomeType.Reject } };
        } else {
            return Evaluation{ .outcome = Outcome{
                .outcomeType = OutcomeType.MoveToAnotherWorkflow,
                .targetWorkflowName = evaluationString,
            } };
        }
    }

    fn parseItem(line: []const u8) !Item {
        var item = Item{};
        var featureSplit = std.mem.split(u8, line[1 .. line.len - 1], ",");
        while (featureSplit.next()) |feature| {
            const value = try util.toUsize(feature[2..]);
            switch (parseFeature(feature[0])) {
                Feature.ExtremelyCoolLooking => item.extremelyCoolLooking = value,
                Feature.Musical => item.musical = value,
                Feature.Aerodynamic => item.aerodynamic = value,
                Feature.Shiny => item.shiny = value,
            }
        }
        return item;
    }

    pub fn deinit(self: *Self) void {
        var workflowIter = self.workflows.valueIterator();
        while (workflowIter.next()) |workflow| {
            workflow.evaluations.deinit();
        }
        self.workflows.deinit();
        self.items.deinit();
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var sum: usize = 0;

    var data = try Data.init(allocator, list);
    defer data.deinit();

    for (data.items.items) |item| {
        var workflowIter = data.workflows.get("in").?;
        while (true) {
            var outcome = workflowIter.evaluate(item);
            switch (outcome.outcomeType) {
                OutcomeType.Accept => {
                    sum += item.featureSum();
                    break;
                },
                OutcomeType.Reject => {
                    break;
                },
                OutcomeType.MoveToAnotherWorkflow => {
                    workflowIter = data.workflows.get(outcome.targetWorkflowName.?).?;
                },
            }
        }
    }

    return sum;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\px{a<2006:qkq,m>2090:A,rfg}
        \\pv{a>1716:R,A}
        \\lnx{m>1548:A,A}
        \\rfg{s<537:gd,x>2440:R,A}
        \\qs{s>3448:A,lnx}
        \\qkq{x<1416:A,crn}
        \\crn{x>2662:A,R}
        \\in{s<1351:px,qqz}
        \\qqz{s>2770:qs,m<1801:hdj,R}
        \\gd{a>3333:R,R}
        \\hdj{m>838:A,pv}
        \\
        \\{x=787,m=2655,a=1222,s=2876}
        \\{x=1679,m=44,a=2067,s=496}
        \\{x=2036,m=264,a=79,s=2244}
        \\{x=2461,m=1339,a=466,s=291}
        \\{x=2127,m=1623,a=2188,s=1013}
    );
    defer list.deinit();

    const testValue: usize = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 19114);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-19.txt");
    defer data.deinit();

    const testValue: usize = try part1(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 0);
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
        \\...
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 377025);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-19.txt");
    defer data.deinit();

    const testValue: usize = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 0);
}
