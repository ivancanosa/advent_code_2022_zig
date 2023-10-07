const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

const Range = struct {
    left: u32,
    right: u32,
};

fn isFullyContainedOneSide(s0: Range, s1: Range) bool {
    return s0.left >= s1.left and s0.right <= s1.right;
}

fn overlapsOneSide(s0: Range, s1: Range) bool {
    return (s0.left >= s1.left and s0.left <= s1.right) or
        (s0.right >= s1.left and s0.right <= s1.right);
}

fn overlaps(s0: Range, s1: Range) bool {
    return overlapsOneSide(s0, s1) or overlapsOneSide(s1, s0);
}

fn isFullyContained(s0: Range, s1: Range) bool {
    return isFullyContainedOneSide(s0, s1) or isFullyContainedOneSide(s1, s0);
}

fn generateRanges(allocator: std.mem.Allocator, lines: ArrayList([]u8)) !ArrayList([2]Range) {
    var result = ArrayList([2]Range).init(allocator);
    for (lines.items) |line| {
        var rangePair: [2]Range = undefined;
        var it_range = std.mem.split(u8, line, ",");
        var i_range: u32 = 0;
        while (it_range.next()) |substr| : (i_range += 1) {
            var it_value = std.mem.split(u8, substr, "-");
            var i_value: u32 = 0;
            var values: [2]u32 = undefined;
            while (it_value.next()) |substr2| : (i_value += 1) {
                values[i_value] = try std.fmt.parseInt(u32, substr2, 10);
            }
            rangePair[i_range] = Range{ .left = values[0], .right = values[1] };
        }
        try result.append(rangePair);
    }

    return result;
}

// Ex 0

fn computeFullyContained(rangesVec: ArrayList([2]Range)) u32 {
    var result: u32 = 0;
    for (rangesVec.items) |rangePair| {
        if (isFullyContained(rangePair[0], rangePair[1])) {
            result += 1;
        }
    }

    return result;
}

// Ex 0

fn computeOverlaps(rangesVec: ArrayList([2]Range)) u32 {
    var result: u32 = 0;
    for (rangesVec.items) |rangePair| {
        if (overlaps(rangePair[0], rangePair[1])) {
            result += 1;
        }
    }

    return result;
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

    const rangesVec = try generateRanges(allocator, lines);
    defer rangesVec.deinit();

    const result0: u32 = computeFullyContained(rangesVec);
    const result1: u32 = computeOverlaps(rangesVec);
    std.debug.print("Exercise 0: {}\n", .{result0});
    std.debug.print("Exercise 1: {}\n", .{result1});
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

test "isFullyContained" {
    const s0 = Range(2, 4);
    const s1 = Range(6, 8);
    const s2 = Range(2, 3);
    const s3 = Range(4, 5);
    const s4 = Range(6, 6);
    const s5 = Range(5, 6);
    try std.testing.expectEqual(isFullyContained(s0, s1), false);
    try std.testing.expectEqual(isFullyContained(s2, s3), false);
    try std.testing.expectEqual(isFullyContained(s4, s5), true);
}
