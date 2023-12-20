const std = @import("std");
const util = @import("util.zig");
const mem = std.mem;
const print = std.debug.print;

const CardType = enum {
    fiveOfAKind,
    fourOfAKind,
    fullHouse,
    threeOfAKind,
    twoPair,
    onePair,
    highCard,

    fn name(self: CardType) []const u8 {
        return switch (self) {
            CardType.fiveOfAKind => "fiveOfAKind",
            CardType.fourOfAKind => "fourOfAKind",
            CardType.fullHouse => "fullHouse",
            CardType.threeOfAKind => "threeOfAKind",
            CardType.twoPair => "twoPair",
            CardType.onePair => "onePair",
            CardType.highCard => "highCard",
        };
    }
};

fn valueMapperNoJoker(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result: []u8 = try allocator.alloc(u8, input.len);
    for (input, 0..) |char, index| {
        result[index] = switch (char) {
            'A' => 14,
            'K' => 13,
            'Q' => 12,
            'J' => 11,
            'T' => 10,
            else => char - '0',
        };
    }
    return result;
}

fn cardTypeMapperNoJoker(allocator: std.mem.Allocator, cards: []const u8) !?CardType {
    var dict: std.AutoHashMap(u8, i64) = std.AutoHashMap(u8, i64).init(allocator);
    defer dict.deinit();

    for (cards) |card| {
        const countRaw: ?i64 = dict.get(card);
        if (countRaw) |count| {
            try dict.put(card, count + 1);
        } else {
            try dict.put(card, 1);
        }
    }
    if (dict.count() == 1) {
        return CardType.fiveOfAKind;
    } else if (dict.count() == 2) {
        if (dict.get(cards[0]).? == 4 or dict.get(cards[0]).? == 1) {
            return CardType.fourOfAKind;
        } else if (dict.get(cards[0]).? == 3 or dict.get(cards[0]).? == 2) {
            return CardType.fullHouse;
        }
    } else if (dict.count() == 5) {
        return CardType.highCard;
    } else {
        var countOfPairs: i64 = 0;
        var dictIter = dict.iterator();
        while (dictIter.next()) |card| {
            if (card.value_ptr.* == 3) {
                return CardType.threeOfAKind;
            } else if (card.value_ptr.* == 2) {
                countOfPairs += 1;
            }
        }
        if (countOfPairs == 2) {
            return CardType.twoPair;
        } else {
            return CardType.onePair;
        }
    }
    @panic("no card type detected");
}

const Card = struct {
    const Self = @This();
    cards: []const u8,
    value: []const u8,
    bid: i64,
    type: CardType,
    allocator: std.mem.Allocator,

    pub fn initNoJoker(allocator: std.mem.Allocator, cards: []const u8, bid: i64) !Card {
        var cardType = try cardTypeMapperNoJoker(allocator, cards);
        var copyCards = try allocator.dupe(u8, cards);
        return .{
            .cards = copyCards,
            .bid = bid,
            .type = cardType.?,
            .allocator = allocator,
            .value = try valueMapperNoJoker(allocator, cards),
        };
    }

    pub fn initJoker(allocator: std.mem.Allocator, cards: []const u8, bid: i64) !Card {
        var cardType = try cardTypeMapperJoker(allocator, cards);
        var copyCards = try allocator.dupe(u8, cards);
        return .{
            .cards = copyCards,
            .bid = bid,
            .type = cardType.?,
            .allocator = allocator,
            .value = try valueMapperJoker(allocator, cards),
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.value);
        self.allocator.free(self.cards);
    }
};

pub fn part1(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var items: []Card = try allocator.alloc(Card, list.items.len);
    defer allocator.free(items);
    defer {
        for (items) |item| {
            item.deinit();
        }
    }

    for (list.items, 0..) |line, index| {
        // print("line={s}\n", .{line});
        var elements = mem.split(u8, line, " ");
        var cards = elements.next().?;
        const bid = try util.toI64(elements.next().?);
        var card: Card = try Card.initNoJoker(allocator, cards, bid);
        items[index] = card;
    }

    std.mem.sort(Card, items, {}, comptime sortCards);

    var sum: i64 = 0;
    for (items, 1..) |item, rank| {
        const ranki64: i64 = @bitCast(rank);
        sum += item.bid * ranki64;
        // print("{s} - {d}*{d} - {d} -> {d}\n", .{ item.cards, ranki64, item.bid, @intFromEnum(item.type), sum });
    }
    return sum;
}

fn sortCards(_: void, lhs: Card, rhs: Card) bool {
    const lt = @intFromEnum(lhs.type);
    const rt = @intFromEnum(rhs.type);
    if (lt > rt) {
        return true;
    } else if (lt < rt) {
        return false;
    }
    for (0..5) |cardIndex| {
        const l: u8 = lhs.value[cardIndex];
        const r: u8 = rhs.value[cardIndex];
        if (l < r) {
            return true;
        } else if (l > r) {
            return false;
        }
    }
    return false;
}

test "part 1 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    );
    defer list.deinit();

    const testValue: i64 = try part1(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 6440);
}

test "part 1 test 2" {
    var t = try cardTypeMapperNoJoker(std.testing.allocator, "KK677");

    try std.testing.expectEqual(t, CardType.twoPair);
}

test "part 1 test 3" {
    var t = try cardTypeMapperNoJoker(std.testing.allocator, "T55J5");

    try std.testing.expectEqual(t, CardType.threeOfAKind);
}

test "part 1 test 4" {
    var t = try cardTypeMapperNoJoker(std.testing.allocator, "32T3K");

    try std.testing.expectEqual(t, CardType.onePair);
}

test "part 1 test 5" {
    var t = try cardTypeMapperNoJoker(std.testing.allocator, "4KTJ4");

    try std.testing.expectEqual(t, CardType.onePair);
}

test "part 1 test 6" {
    var t = try cardTypeMapperNoJoker(std.testing.allocator, "A444A");

    try std.testing.expectEqual(t, CardType.fullHouse);
}

test "part 1 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-7.txt");
    defer data.deinit();

    const testValue: i64 = try part1(std.testing.allocator, data.lines);
    // 248166301 is too
    try std.testing.expectEqual(testValue, 248179786);
}

pub fn part2(allocator: std.mem.Allocator, list: std.ArrayList([]const u8)) !i64 {
    var items: []Card = try allocator.alloc(Card, list.items.len);
    defer allocator.free(items);
    defer {
        for (items) |item| {
            item.deinit();
        }
    }

    for (list.items, 0..) |line, index| {
        // print("line={s}\n", .{line});
        var elements = mem.split(u8, line, " ");
        var cards = elements.next().?;
        const bid = try util.toI64(elements.next().?);
        var card: Card = try Card.initJoker(allocator, cards, bid);
        items[index] = card;
    }

    std.mem.sort(Card, items, {}, comptime sortCards);

    var sum: i64 = 0;
    for (items, 1..) |item, rank| {
        const ranki64: i64 = @bitCast(rank);
        sum += item.bid * ranki64;
        // if (std.mem.indexOf(u8, item.cards, "J")) |_| {
        // print("{s} - {d}*{d} - {s} -> {d}\n", .{ item.cards, ranki64, item.bid, item.type.name(), sum });
        // }
    }
    return sum;
}

fn cardTypeMapperJoker(allocator: std.mem.Allocator, cards: []const u8) !?CardType {
    var countOfJokers: i64 = 0;
    for (cards) |card| {
        if (card == 'J') {
            countOfJokers += 1;
        }
    }
    if (countOfJokers == 0) {
        return try cardTypeMapperNoJoker(allocator, cards);
    }

    var dict: std.AutoHashMap(u8, i64) = std.AutoHashMap(u8, i64).init(allocator);
    defer dict.deinit();

    for (cards) |card| {
        const countRaw: ?i64 = dict.get(card);
        if (card == 'J') {
            continue;
        }
        if (countRaw) |count| {
            try dict.put(card, count + 1);
        } else {
            try dict.put(card, 1);
        }
    }
    var countOfPairs: i64 = 0;
    var dictIter = dict.iterator();
    while (dictIter.next()) |card| {
        if (card.value_ptr.* == 4) {
            return CardType.fiveOfAKind;
        } else if (card.value_ptr.* == 3) {
            if (countOfJokers == 2) {
                return CardType.fiveOfAKind;
            }
            return CardType.fourOfAKind;
        } else if (card.value_ptr.* == 2) {
            countOfPairs += 1;
        }
    }
    if (countOfPairs == 0) {
        if (countOfJokers == 5 or countOfJokers == 4) {
            return CardType.fiveOfAKind;
        } else if (countOfJokers == 3) {
            return CardType.fourOfAKind;
        } else if (countOfJokers == 2) {
            return CardType.threeOfAKind;
        } else if (countOfJokers == 1) {
            return CardType.onePair;
        }
    } else if (countOfPairs == 1) {
        if (countOfJokers == 3) {
            return CardType.fiveOfAKind;
        } else if (countOfJokers == 2) {
            return CardType.fourOfAKind;
        } else if (countOfJokers == 1) {
            return CardType.threeOfAKind;
        }
    } else if (countOfPairs == 2) {
        return CardType.fullHouse;
    }
    @panic("no card type detected");
}

fn valueMapperJoker(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result: []u8 = try allocator.alloc(u8, input.len);
    for (input, 0..) |char, index| {
        result[index] = switch (char) {
            'A' => 14,
            'K' => 13,
            'Q' => 12,
            'J' => 1,
            'T' => 10,
            else => char - '0',
        };
    }
    return result;
}

test "part 2 test 1" {
    var list = try util.parseToListOfStrings([]const u8,
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    );
    defer list.deinit();

    const testValue: i64 = try part2(std.testing.allocator, list);
    try std.testing.expectEqual(testValue, 5905);
}

test "part 2 test 2" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "T55J5");

    try std.testing.expectEqual(t, CardType.fourOfAKind);
}

test "part 2 test 3" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "4KTJ4");

    try std.testing.expectEqual(t, CardType.threeOfAKind);
}

test "part 2 test 4" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "JJJJA");

    try std.testing.expectEqual(t, CardType.fiveOfAKind);
}

test "part 2 test 6" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "JJJAA");

    try std.testing.expectEqual(t, CardType.fiveOfAKind);
}

test "part 2 test 7" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "9988J");

    try std.testing.expectEqual(t, CardType.fullHouse);
}

test "part 2 test 8" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "KTJJT");

    try std.testing.expectEqual(t, CardType.fourOfAKind);
}

test "part 2 test 9" {
    var t = try cardTypeMapperJoker(std.testing.allocator, "2J222");

    try std.testing.expectEqual(t, CardType.fiveOfAKind);
}

test "part 2 full" {
    var data = try util.openFile(std.testing.allocator, "data/input-7.txt");
    defer data.deinit();

    const testValue: i64 = try part2(std.testing.allocator, data.lines);
    try std.testing.expectEqual(testValue, 247885995);
}
