const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

fn getShift(allocator: std.mem.Allocator, str: []const u8, size: u8) !u32 {
    var set = std.AutoHashMap(u8, void).init(allocator);
    defer set.deinit();
    for (0..str.len) |i| {
        set.clearRetainingCapacity();
        for (0..size) |j| {
            _ = try set.put(str[i + j], {});
        }
        if (set.count() == size) {
            return @intCast(i + size);
        }
    }
    unreachable;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.detectLeaks();
    const allocator = gpa.allocator();
    var lines = try getLines(allocator, "input");
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const result0 = try getShift(allocator, lines.items[0], 4);
    const result1 = try getShift(allocator, lines.items[0], 14);

    std.debug.print("Result 0: {}\n", .{result0});
    std.debug.print("Result 1: {}\n", .{result1});
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
    var buf: [5000]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const my_line = try std.fmt.allocPrint(allocator, "{s}", .{line});
        try lines.append(my_line);
    }

    return lines;
}

test "testGetShift" {
    var allocator = std.testing.allocator;
    try std.testing.expectEqual(getShift(allocator, "bvwbjplbgvbhsrlpgdmjqwftvncz", 4), 5);
    try std.testing.expectEqual(getShift(allocator, "nppdvjthqldpwncqszvftbrmjlhg", 4), 6);
    try std.testing.expectEqual(getShift(allocator, "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg", 4), 10);
    try std.testing.expectEqual(getShift(allocator, "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw", 4), 11);

    try std.testing.expectEqual(getShift(allocator, "mjqjpqmgbljsphdztnvjfqwrcgsmlb", 14), 19);
    try std.testing.expectEqual(getShift(allocator, "bvwbjplbgvbhsrlpgdmjqwftvncz", 14), 23);
}
