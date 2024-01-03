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
    GreaterThanOrEqual,
    LessThanOrEqual,

    pub fn op(self: Self, value: usize, other: usize) bool {
        return switch (self) {
            Operation.LessThan => value < other,
            Operation.GreaterThan => value > other,
            else => @panic("*orEqual are not meant for evaluation"),
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
    allocator: std.mem.Allocator,

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

    pub fn visitAcceptRanges(self: Self, allFeatureRanges: *std.ArrayList(std.ArrayList(FeatureRange)), ongoingFilters: std.ArrayList(FeatureRange)) !void {
        if (self.feature) |featureRaw| {
            switch (self.outcome.outcomeType) {
                OutcomeType.Accept => {
                    var newOngoingFilters = try self.copyFeatureRanges(ongoingFilters);
                    if (self.outcome.outcomeType != OutcomeType.Accept) {
                        defer {
                            for (newOngoingFilters.items) |filter| {
                                filter.ranges.deinit();
                            }
                            newOngoingFilters.deinit();
                        }
                    }
                    for (newOngoingFilters.items) |*ongoingFilter| {
                        if (ongoingFilter.feature == featureRaw) {
                            try ongoingFilter.filter(self.operation.?, self.value.?);
                        }
                    }
                    if (self.outcome.outcomeType == OutcomeType.Accept) {
                        try allFeatureRanges.append(newOngoingFilters);
                    }
                },
                else => @panic("not yet implemented"),
            }
        } else {
            if (self.outcome.outcomeType == OutcomeType.Accept) {
                try allFeatureRanges.append(try self.copyFeatureRanges(ongoingFilters));
            }
        }
    }

    fn copyFeatureRanges(self: Self, ongoingFilters: std.ArrayList(FeatureRange)) !std.ArrayList(FeatureRange) {
        var newFeatureRange = std.ArrayList(FeatureRange).init(self.allocator);
        for (ongoingFilters.items) |filter| {
            try newFeatureRange.append(try FeatureRange.copyFrom(filter));
        }
        return newFeatureRange;
    }

    pub fn visitPath(self: Self, data: Data, allPaths: *std.ArrayList(WorkflowPath), ongoingPath: WorkflowPath) std.mem.Allocator.Error!WorkflowPath {
        var newPath = try ongoingPath.dupe();
        if (self.feature) |featureRaw| {
            try newPath.path.append(FeatureSelectionCriteria{
                .feature = featureRaw,
                .operation = self.operation,
                .value = self.value,
            });
        }
        if (self.outcome.outcomeType == OutcomeType.Accept or self.outcome.outcomeType == OutcomeType.Reject) {
            // path is finished
            newPath.outcomeType = self.outcome.outcomeType;
            try allPaths.append(newPath);
        } else {
            // path continues into another workflow
            var nextWorkflow: Workflow = data.workflows.get(self.outcome.targetWorkflowName.?).?;
            try nextWorkflow.visitPath(data, allPaths, newPath);
        }
        var returnPath = try ongoingPath.dupe();
        if (self.feature) |featureRaw| {
            try returnPath.path.append(FeatureSelectionCriteria{
                .feature = featureRaw,
                .operation = switch (self.operation.?) {
                    Operation.GreaterThan => Operation.LessThanOrEqual,
                    Operation.LessThan => Operation.GreaterThanOrEqual,
                    else => @panic("*orEqual are not supported in path visit"),
                },
                .value = self.value,
            });
        }
        return returnPath;
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

    pub fn visitAcceptRanges(self: Self, allFeatureRanges: *std.ArrayList(std.ArrayList(FeatureRange)), ongoingFilters: std.ArrayList(FeatureRange)) !void {
        for (self.evaluations.items) |evaluation| {
            try evaluation.visitAcceptRanges(allFeatureRanges, ongoingFilters);
        }
    }

    pub fn visitPath(self: Self, data: Data, allPaths: *std.ArrayList(WorkflowPath), ongoingPath: WorkflowPath) !void {
        var pathIter = ongoingPath;
        for (self.evaluations.items) |evaluation| {
            var newPathIter = try evaluation.visitPath(data, allPaths, pathIter);
            pathIter.deinit();
            pathIter = newPathIter;
        }
        pathIter.deinit();
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
                var evaluation = parseEvaluation(allocator, ingress);

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
                try evaluations.append(parseEvaluation(allocator, split));
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

    fn parseEvaluation(allocator: std.mem.Allocator, evaluationString: []const u8) Evaluation {
        if (std.mem.eql(u8, evaluationString, "A")) {
            return Evaluation{ .allocator = allocator, .outcome = Outcome{ .outcomeType = OutcomeType.Accept } };
        } else if (std.mem.eql(u8, evaluationString, "R")) {
            return Evaluation{ .allocator = allocator, .outcome = Outcome{ .outcomeType = OutcomeType.Reject } };
        } else {
            return Evaluation{ .allocator = allocator, .outcome = Outcome{
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

const Range = struct {
    start: usize,
    end: usize,
};

const FeatureRange = struct {
    const Self = @This();
    feature: Feature,
    // TODO: simplify to a single range
    ranges: std.ArrayList(Range),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, feature: Feature) !Self {
        var ranges = std.ArrayList(Range).init(allocator);
        try ranges.append(Range{ .start = 1, .end = 4000 });
        return Self{
            .feature = feature,
            .ranges = ranges,
            .allocator = allocator,
        };
    }

    pub fn copyFrom(other: FeatureRange) !Self {
        var ranges = std.ArrayList(Range).init(other.allocator);
        for (other.ranges.items) |range| {
            try ranges.append(range);
        }
        return FeatureRange{
            .feature = other.feature,
            .allocator = other.allocator,
            .ranges = ranges,
        };
    }

    pub fn filter(self: *Self, operation: Operation, value: usize) !void {
        var newRanges = std.ArrayList(Range).init(self.allocator);
        for (self.ranges.items) |range| {
            // if range is not impacted, just copy it
            if ((range.start > value and operation == Operation.GreaterThan) or
                (range.end < value and operation == Operation.LessThan) or
                (range.start >= value and operation == Operation.GreaterThanOrEqual) or
                (range.end <= value and operation == Operation.LessThanOrEqual))
            {
                try newRanges.append(range);
                continue;
            }
            // if range is missing entire range, skip it
            if ((value <= range.start and operation == Operation.LessThan) or
                (value >= range.end and operation == Operation.GreaterThan) or
                (value < range.start and operation == Operation.LessThanOrEqual) or
                (value > range.end and operation == Operation.GreaterThanOrEqual))
            {
                continue;
            }
            // if range is covering partial range, change the range boundaries
            if (value > range.start and operation == Operation.LessThan) {
                try newRanges.append(Range{ .start = range.start, .end = value - 1 });
                continue;
            }
            if (value < range.end and operation == Operation.GreaterThan) {
                try newRanges.append(Range{ .start = value + 1, .end = range.end });
                continue;
            }
            if (value >= range.start and operation == Operation.LessThanOrEqual) {
                try newRanges.append(Range{ .start = range.start, .end = value });
                continue;
            }
            if (value <= range.end and operation == Operation.GreaterThanOrEqual) {
                try newRanges.append(Range{ .start = value, .end = range.end });
                continue;
            }
        }
        self.ranges.deinit();
        self.ranges = newRanges;
    }

    pub fn deinit(self: *Self) void {
        self.ranges.deinit();
    }
};

const FeatureSelectionCriteria = struct {
    feature: ?Feature = null,
    operation: ?Operation = null,
    value: ?usize = null,

    pub fn debug(self: FeatureSelectionCriteria) void {
        if (self.feature) |featureRaw| {
            print("{} {} {d}", .{ featureRaw, self.operation.?, self.value.? });
        } else {
            print("(pass through)", .{});
        }
    }
};

const WorkflowPath = struct {
    const Self = @This();
    path: std.ArrayList(FeatureSelectionCriteria),
    outcomeType: ?OutcomeType = null,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .path = std.ArrayList(FeatureSelectionCriteria).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.path.deinit();
    }

    pub fn dupe(self: Self) !WorkflowPath {
        var newPath = try WorkflowPath.init(self.allocator);
        for (self.path.items) |step| {
            try newPath.path.append(step);
        }
        newPath.outcomeType = self.outcomeType;
        return newPath;
    }

    pub fn debug(self: Self) void {
        for (self.path.items) |step| {
            step.debug();
            print(" -> ", .{});
        }
        print("[{}]\n", .{self.outcomeType.?});
    }
};

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !usize {
    var data = try Data.init(allocator, list);
    defer data.deinit();

    var allPaths = std.ArrayList(WorkflowPath).init(allocator);
    defer {
        for (allPaths.items) |*path| {
            path.deinit();
        }
        allPaths.deinit();
    }

    var ongoingPath = try WorkflowPath.init(allocator);
    defer {
        ongoingPath.deinit();
    }

    try data.workflows.get("in").?.visitPath(data, &allPaths, ongoingPath);

    // print("\n", .{});
    // for (allPaths.items) |path| {
    //     path.debug();
    // }

    var ongoingList = std.ArrayList(FeatureRange).init(allocator);
    defer {
        for (ongoingList.items) |*featureRange| {
            featureRange.deinit();
        }
        ongoingList.deinit();
    }

    try ongoingList.append(try FeatureRange.init(allocator, Feature.Aerodynamic));
    try ongoingList.append(try FeatureRange.init(allocator, Feature.ExtremelyCoolLooking));
    try ongoingList.append(try FeatureRange.init(allocator, Feature.Musical));
    try ongoingList.append(try FeatureRange.init(allocator, Feature.Shiny));
    for (allPaths.items) |path| {
        for (path.path.items) |criteria| {
            // TODO: check if Rejects can be removed from the allPaths completely
            if (path.outcomeType == OutcomeType.Accept) {
                for (ongoingList.items) |*featureRange| {
                    if (featureRange.feature == criteria.feature) {
                        try featureRange.filter(criteria.operation.?, criteria.value.?);
                    }
                }
            }
        }
    }

    var possibilities: usize = 1;
    for (ongoingList.items) |featureRanges| {
        for (featureRanges.ranges.items) |featureRange| {
            possibilities *= featureRange.end - featureRange.start + 1;
        }
    }
    return possibilities;
}

test "part 2 test 0.1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\in{A}
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4000 * 4000 * 4000 * 4000);
}

// test "part 2 test 0.2" {
//     var list = try util.parseToListOfStrings([]const u8,
//         \\in{R}
//     );
//     defer list.deinit();

//     const testValue: usize = try part2(std.testing.allocator, list);
//     try std.testing.expectEqual(testValue, 0);
// }

test "part 2 test 0.3" {
    var list = try util.parseToListOfStrings([]const u8,
        \\in{s<2001:A}
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4000 * 4000 * 4000 * 2000);
}

test "part 2 test 0.4" {
    var list = try util.parseToListOfStrings([]const u8,
        \\in{s<2001:R,A}
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4000 * 4000 * 4000 * 2000);
}

test "part 2 test 0.5" {
    var list = try util.parseToListOfStrings([]const u8,
        \\in{s<2001:x,R}
        \\x{x<2001:A,R}
    );
    defer list.deinit();

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 4000 * 4000 * 2000 * 2000);
}

test "part 2 test 1" {
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

    const testValue: usize = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 167409079868000);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-19.txt");
    defer data.deinit();

    const testValue: usize = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 0);
}
