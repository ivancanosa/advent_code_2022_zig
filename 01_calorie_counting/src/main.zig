const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

fn toInt(str: []u8) !u32 {
    return try std.fmt.parseInt(u32, str, 10);
}

fn getLines(allocator: std.mem.Allocator, filename: []const u8) !ArrayList([]u8) {
    var lines = ArrayList([]u8).init(allocator);

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var my_line = try allocator.alloc(u8, line.len);
        @memcpy(my_line, line);
        try lines.append(my_line);
    }

    return lines;
}

pub fn greater(_: u32, lhs: u32, rhs: u32) bool {
    return lhs > rhs;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var foodVec = ArrayList(u32).init(allocator);
    defer foodVec.deinit();

    var lines = try getLines(allocator, "input");
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var current_food: u32 = 0;
    for (lines.items) |line| {
        if (line.len > 0) {
            current_food += try toInt(line);
        } else {
            try foodVec.append(current_food);
            current_food = 0;
        }
    }

    var max: u32 = 0;
    for (foodVec.items) |food| {
        if (max < food) {
            max = food;
        }
    }
    var ctx: u32 = 0;
    std.sort.heap(u32, foodVec.items, ctx, greater);

    //Question 1
    std.debug.print("Top 1: {}\n", .{foodVec.items[0]});

    //Question 2
    const total = foodVec.items[0] + foodVec.items[1] + foodVec.items[2];
    std.debug.print("Top 3 acc: {}\n", .{total});
}
