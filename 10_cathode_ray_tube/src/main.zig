const std = @import("std");

const Command = union(enum) {
    Noop: void,
    Addx: i32,
};

pub fn parseCommands(ally: std.mem.Allocator, lines: std.ArrayList([]u8)) !std.ArrayList(Command) {
    var commands = std.ArrayList(Command).init(ally);
    for (lines.items) |line| {
        var command = Command{ .Noop = undefined };
        var it = std.mem.split(u8, line, " ");
        var slice0 = it.next().?;
        if (std.mem.eql(u8, slice0, "addx")) {
            var slice1 = it.next().?;
            const num = try std.fmt.parseInt(i32, slice1, 10);
            command = Command{ .Addx = num };
        }
        try commands.append(command);
    }
    return commands;
}

pub fn computeSignalAcc(cycle: i32, x: i32, acc: i32) i32 {
    if (cycle < 20) {
        return acc;
    }
    if (@mod((cycle - 20), 40) == 0) {
        return acc + cycle * x;
    }
    return acc;
}

pub fn computeSignal(commands: std.ArrayList(Command)) i32 {
    var acc: i32 = 0;
    var cycle: i32 = 1;
    var x: i32 = 1;
    for (commands.items) |command| {
        _ = switch (command) {
            Command.Noop => blk: {
                acc = computeSignalAcc(cycle, x, acc);
                cycle += 1;
                break :blk void;
            },
            Command.Addx => |num| blk: {
                acc = computeSignalAcc(cycle, x, acc);
                cycle += 1;
                acc = computeSignalAcc(cycle, x, acc);
                cycle += 1;
                x += num;
                break :blk void;
            },
        };
    }

    return acc;
}

pub fn printCRTCycle(cycle: i32, x: i32) !void {
    const collumn = @mod(cycle, 40);
    const dist = try std.math.absInt(collumn - x);
    if (dist <= 1) {
        std.debug.print("#", .{});
    } else {
        std.debug.print(".", .{});
    }
    if (@mod(cycle, 40) == 0 and cycle > 20) {
        std.debug.print("\n", .{});
    }
}

pub fn printCRT(commands: std.ArrayList(Command)) !void {
    var cycle: i32 = 1;
    var x: i32 = 1;
    for (commands.items) |command| {
        _ = switch (command) {
            Command.Noop => blk: {
                try printCRTCycle(cycle, x);
                cycle += 1;
                break :blk void;
            },
            Command.Addx => |num| blk: {
                try printCRTCycle(cycle, x);
                cycle += 1;
                x += num;
                try printCRTCycle(cycle, x);
                cycle += 1;
                break :blk void;
            },
        };
    }
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

    var commands = try parseCommands(allocator, lines);
    defer commands.deinit();

    const result0 = computeSignal(commands);
    std.debug.print("Result0: {}\n", .{result0});
    try printCRT(commands);
}

fn isEmptyStr(str: []const u8) bool {
    for (str) |c| {
        if (c != ' ' and c != '\t') {
            return false;
        }
    }
    return true;
}

fn getLines(allocator: std.mem.Allocator, filename: []const u8) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(allocator);

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
