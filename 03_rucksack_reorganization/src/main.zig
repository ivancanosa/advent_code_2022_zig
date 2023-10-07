const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

fn getItemPriority(item: u8) u8 {
    if (item >= 'a' and item <= 'z') {
        return item - 'a' + 1;
    }
    if (item >= 'A' and item <= 'Z') {
        return item - 'A' + 27;
    }
    unreachable;
}

// Exercise 1

fn getRucksackScore(allocator: std.mem.Allocator, rucksack: []const u8) !u32 {
    const size = rucksack.len;
    var score: u32 = 0;

    var set = std.AutoHashMap(u8, void).init(allocator);
    defer set.deinit();

    var discardedSet = std.AutoHashMap(u8, void).init(allocator);
    defer discardedSet.deinit();

    for (0..size / 2) |i| {
        try set.put(rucksack[i], {});
    }

    for (size / 2..size) |i| {
        if (set.contains(rucksack[i]) and !discardedSet.contains(rucksack[i])) {
            score += getItemPriority(rucksack[i]);
            try discardedSet.put(rucksack[i], {});
        }
    }

    return score;
}

fn ex0(allocator: std.mem.Allocator, lines: ArrayList([]u8)) !u32 {
    var score: u32 = 0;
    for (lines.items) |line| {
        score += try getRucksackScore(allocator, line);
    }

    return score;
}

// Exercise 2

fn getGroupScore(allocator: std.mem.Allocator, s0: []const u8, s1: []const u8, s2: []const u8) !u32 {
    var set0 = std.AutoHashMap(u8, void).init(allocator);
    defer set0.deinit();

    var set1 = std.AutoHashMap(u8, void).init(allocator);
    defer set1.deinit();

    var groupItem: ?u8 = null;

    for (s0) |item| {
        try set0.put(item, {});
    }

    for (s1) |item| {
        if (set0.contains(item)) {
            try set1.put(item, {});
        }
    }
    for (s2) |item| {
        if (set1.contains(item)) {
            groupItem = item;
        }
    }

    return getItemPriority(groupItem.?);
}

fn ex1(allocator: std.mem.Allocator, lines: ArrayList([]u8)) !u32 {
    var score: u32 = 0;
    var i: u32 = 0;
    while (i < lines.items.len) : (i += 3) {
        score += try getGroupScore(allocator, lines.items[i], lines.items[i + 1], lines.items[i + 2]);
    }

    return score;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var lines = try getLines(allocator, "input");
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const score0 = try ex0(allocator, lines);
    const score1 = try ex1(allocator, lines);
    std.debug.print("Score 0: {}\n", .{score0});
    std.debug.print("Score 1: {}\n", .{score1});
}

// Auxiliary functions

fn isEmptyStr(str: []const u8) bool {
    for (str) |c| {
        if (c != ' ' and c != '\t') {
            return false;
        }
    }
    return true;
}

fn getLines(allocator: std.mem.Allocator, filename: []const u8) !ArrayList([]u8) {
    var lines = ArrayList([]u8).init(allocator);

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const my_line = try std.fmt.allocPrint(allocator, "{s}", .{line});
        try lines.append(my_line);
    }

    return lines;
}

// Tests

test "getItemPriority" {
    try std.testing.expectEqual(getItemPriority('a'), 1);
    try std.testing.expectEqual(getItemPriority('z'), 26);
    try std.testing.expectEqual(getItemPriority('A'), 27);
    try std.testing.expectEqual(getItemPriority('L'), 38);
    try std.testing.expectEqual(getItemPriority('Z'), 52);
}

test "getRucksackScore" {
    var allocator = std.testing.allocator;
    try std.testing.expectEqual(getRucksackScore(allocator, "vJrwpWtwJgWrhcsFMMfFFhFp"), getItemPriority('p'));
    try std.testing.expectEqual(getRucksackScore(allocator, "jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL"), getItemPriority('L'));
}
