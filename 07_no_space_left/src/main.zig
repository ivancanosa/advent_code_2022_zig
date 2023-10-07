const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

const File = struct {
    name: []const u8,
    size: u64,
};

const Directory = struct {
    name: []const u8,
    entries: ArrayList(Entry),
    parent: ?*Directory,

    pub fn init(allocator: std.mem.Allocator, str: []const u8, parentOpt: ?*Directory) Directory {
        if (parentOpt) |parent| {
            return Directory{ .name = str, .entries = ArrayList(Entry).init(allocator), .parent = parent };
        }
        var dir = Directory{ .name = str, .entries = ArrayList(Entry).init(allocator), .parent = null };
        dir.parent = &dir;
        return dir;
    }

    pub fn deinit(self: Directory) void {
        for (self.entries.items) |entry| {
            _ = switch (entry) {
                Entry.file => void,
                Entry.directory => |dir| dir.deinit(),
            };
        }
        self.entries.deinit();
    }
};

const Entry = union(enum) {
    file: File,
    directory: Directory,
};

const State = struct {
    root: *Directory,
    currentDir: *Directory,
};

fn executeCD(state: *State, toDir: []const u8) void {
    if (std.mem.eql(u8, toDir, "/")) {
        state.currentDir = state.root;
        return;
    }
    if (std.mem.eql(u8, toDir, "..")) {
        state.currentDir = state.currentDir.parent.?;
        return;
    }

    for (state.currentDir.entries.items) |*entry| {
        var newDir: ?*Directory = switch (entry.*) {
            Entry.file => null,
            Entry.directory => |*dir| blk: {
                if (std.mem.eql(u8, toDir, dir.name)) {
                    break :blk dir;
                } else {
                    break :blk null;
                }
            },
        };
        if (newDir) |dir| {
            state.currentDir = dir;
            return;
        }
    }
    unreachable;
}

fn executeLS(allocator: std.mem.Allocator, state: *State, lines: ArrayList([]u8), line_count_arg: usize) !void {
    var line_count = line_count_arg;
    while (true) : (line_count += 1) {
        if (line_count >= lines.items.len) {
            break;
        }
        const line = lines.items[line_count];
        if (line[0] == '$') {
            break;
        }

        var firstWord: []const u8 = undefined;
        var secondWord: []const u8 = undefined;

        // Parse words
        var it = std.mem.split(u8, line, " ");
        var wc: u32 = 0;
        while (it.next()) |word| : (wc += 1) {
            if (wc == 0) {
                firstWord = word;
            } else if (wc == 1) {
                secondWord = word;
            }
        }

        // Create entry
        if (std.mem.eql(u8, firstWord, "dir")) {
            var dir = Directory.init(allocator, secondWord, state.currentDir);
            try state.currentDir.entries.append(Entry{ .directory = dir });
        } else {
            const size = try std.fmt.parseInt(u64, firstWord, 10);
            var file = File{ .name = secondWord, .size = size };
            try state.currentDir.entries.append(Entry{ .file = file });
        }
    }
}

fn executeCommands(allocator: std.mem.Allocator, root: *Directory, lines: ArrayList([]u8)) !void {
    var state: State = State{ .root = root, .currentDir = root };

    for (lines.items, 0..) |line, line_count| {
        if (line[0] != '$') {
            continue;
        }

        var command: []const u8 = undefined;
        var arg: []const u8 = undefined;

        // Parse command
        var it = std.mem.split(u8, line, " ");
        var i: u32 = 0;
        while (it.next()) |word| : (i += 1) {
            if (i == 1) {
                command = word;
            } else if (i == 2) {
                arg = word;
            }
        }

        // Execute command
        if (std.mem.eql(u8, command, "cd")) {
            executeCD(&state, arg);
        } else if (std.mem.eql(u8, command, "ls")) {
            try executeLS(allocator, &state, lines, line_count + 1);
        }
    }
}

// Exercise 0

fn filterSize(size: u64) u64 {
    if (size <= 100000) {
        return size;
    }
    return 0;
}

fn computeDirSize(root: Directory, acc: *u64) u64 {
    var size: u64 = 0;
    for (root.entries.items) |entry| {
        switch (entry) {
            Entry.file => |file| size += file.size,
            Entry.directory => |dir| size += computeDirSize(dir, acc),
        }
    }
    if (filterSize(size) > 0) {
        acc.* += size;
    }
    return size;
}

// Exercise 1

fn computeDirSize1(root: Directory, requiredSize: u64, dirToDeleteSize: *u64) u64 {
    var size: u64 = 0;
    for (root.entries.items) |entry| {
        switch (entry) {
            Entry.file => |file| size += file.size,
            Entry.directory => |dir| size += computeDirSize1(dir, requiredSize, dirToDeleteSize),
        }
    }
    if (size >= requiredSize and size < dirToDeleteSize.*) {
        dirToDeleteSize.* = size;
    }
    return size;
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

    var root = Directory.init(allocator, "/", null);
    defer root.deinit();

    try executeCommands(allocator, &root, lines);

    // Ex 0
    var result0: u64 = 0;
    const rootSize = computeDirSize(root, &result0);
    std.debug.print("Result 0: {}\n", .{result0});

    // Ex 1
    const freeSpace = 70000000 - rootSize;
    const requiredSpace = 30000000 - freeSpace;
    var dirToDeleteSize: u64 = rootSize;
    _ = computeDirSize1(root, requiredSpace, &dirToDeleteSize);
    std.debug.print("Result 1: {}\n", .{dirToDeleteSize});
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
