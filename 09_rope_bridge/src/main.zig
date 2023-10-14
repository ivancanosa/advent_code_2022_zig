const std = @import("std");
const ArrayList = std.ArrayList;

const Vec2 = struct {
    const Self = @This();

    x: i32 = 0,
    y: i32 = 0,

    pub fn hash(self: *const Self) i64 {
        return self.x + self.y * 10000;
    }
};

const Rope = struct {
    const Self = @This();

    head: Vec2 = Vec2{},
    tail: Vec2 = Vec2{},

    fn move_head(self: *Self, delta_head: Vec2) !void {
        self.head.x += delta_head.x;
        self.head.y += delta_head.y;

        const dx = self.head.x - self.tail.x;
        const dy = self.head.y - self.tail.y;
        const abs_dx = try std.math.absInt(dx);
        const abs_dy = try std.math.absInt(dy);

        if (abs_dx >= 2 and abs_dy == 0) {
            self.tail.x += @divExact(dx, 2);
        } else if (abs_dy >= 2 and abs_dx == 0) {
            self.tail.y += @divExact(dy, 2);
        } else if (abs_dy >= 2 or abs_dx >= 2) {
            if (abs_dy >= 2) {
                self.tail.y += @divExact(dy, 2);
            } else {
                self.tail.y += dy;
            }

            if (abs_dx >= 2) {
                self.tail.x += @divExact(dx, 2);
            } else {
                self.tail.x += dx;
            }
        }
    }
};

pub fn parseCommands(ally: std.mem.Allocator, lines: ArrayList([]u8)) !ArrayList(Vec2) {
    var commands = ArrayList(Vec2).init(ally);
    for (lines.items) |line| {
        var it = std.mem.split(u8, line, " ");
        var slice0 = it.next().?;
        var slice1 = it.next().?;

        const magnitude = try std.fmt.parseInt(i32, slice1, 10);
        const command = switch (slice0[0]) {
            'R' => Vec2{ .x = 1 },
            'L' => Vec2{ .x = -1 },
            'U' => Vec2{ .y = 1 },
            'D' => Vec2{ .y = -1 },
            else => unreachable,
        };

        for (0..@intCast(magnitude)) |_| {
            try commands.append(command);
        }
    }

    return commands;
}

pub fn traceTail(ally: std.mem.Allocator, commands: ArrayList(Vec2)) !u32 {
    var visited = std.AutoArrayHashMap(i64, void).init(ally);
    defer visited.deinit();

    var rope = Rope{};
    try visited.put(rope.tail.hash(), {});
    for (commands.items) |command| {
        try rope.move_head(command);
        try visited.put(rope.tail.hash(), {});
    }

    return @intCast(visited.count());
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

    const commands = try parseCommands(allocator, lines);
    defer commands.deinit();

    const result0 = try traceTail(allocator, commands);
    std.debug.print("Result 0: {}\n", .{result0});
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
