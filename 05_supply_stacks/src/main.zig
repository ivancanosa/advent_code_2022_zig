const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

const Command = struct {
    countCrates: u32,
    originStack: u32,
    destinyStack: u32,
};

const CratePile = ArrayList(u8);
const Storage = ArrayList(CratePile);
const CommandList = ArrayList(Command);

fn cleanStorage(storage: Storage) void {
    for (storage.items) |stack| {
        stack.deinit();
    }
    storage.deinit();
}

fn cleanCommandList(commandList: CommandList) void {
    commandList.deinit();
}

fn printTopStack(storage: Storage) void {
    for (storage.items) |stack| {
        std.debug.print("{c}", .{stack.items[stack.items.len - 1]});
    }
    std.debug.print("\n", .{});
}

fn getStacks(allocator: std.mem.Allocator, lines: ArrayList([]u8)) !Storage {
    var storage = Storage.init(allocator);
    errdefer cleanStorage(storage);

    for (lines.items, 0..) |line, pile_count| {
        if (line.len == 0) {
            break;
        }
        var it = std.mem.window(u8, line, 3, 4);
        var i: u32 = 0;
        var pile = CratePile.init(allocator);
        try storage.append(pile);
        var isFinalLine: bool = false;
        while (it.next()) |substr| : (i += 1) {
            const char = substr[1];
            try storage.items[pile_count].append(char);
        }
        if (isFinalLine) {}
    }

    const num_piles = storage.items[0].items.len;
    const max_stack_size = storage.items.len;

    // Compute matrix transpose
    for (0..num_piles) |y| {
        for (y..max_stack_size) |x| {
            const aux = storage.items[x].items[y];
            storage.items[x].items[y] = storage.items[y].items[x];
            storage.items[y].items[x] = aux;
        }
    }

    // Clean crates
    for (storage.items) |*pile| {
        _ = pile.pop();
        std.mem.reverse(u8, pile.items);
        while (true) {
            if (pile.items[pile.items.len - 1] == ' ') {
                _ = pile.pop();
            } else {
                break;
            }
        }
    }

    return storage;
}

fn getCommands(allocator: std.mem.Allocator, lines: ArrayList([]u8)) !CommandList {
    var commandList = CommandList.init(allocator);
    errdefer cleanCommandList(commandList);

    for (lines.items) |line| {
        if (line.len <= 1) {
            continue;
        }
        if (line[0] != 'm') {
            continue;
        }
        var it = std.mem.split(u8, line, " ");
        var i: u8 = 0;
        var command: Command = undefined;
        while (it.next()) |word| {
            if (word[0] >= '0' and word[0] <= '9') {
                const num = try std.fmt.parseInt(u32, word, 10);
                if (i == 0) {
                    command.countCrates = num;
                } else if (i == 1) {
                    command.originStack = num - 1;
                } else if (i == 2) {
                    command.destinyStack = num - 1;
                }
                i += 1;
            }
        }
        if (i <= 0 or i >= 4) {
            unreachable;
        }
        try commandList.append(command);
    }

    return commandList;
}

// Exercise 0

fn executeCommands(storage: Storage, commands: CommandList) !void {
    for (commands.items) |command| {
        var originStack: *CratePile = &storage.items[command.originStack];
        var destinyStack: *CratePile = &storage.items[command.destinyStack];
        const cratesToMove = @min(command.countCrates, originStack.items.len);
        for (0..cratesToMove) |_| {
            const crate = originStack.pop();
            try destinyStack.append(crate);
        }
    }
}

// Exercise 1

fn executeCommands1(storage: Storage, commands: CommandList) !void {
    for (commands.items) |command| {
        var originStack: *CratePile = &storage.items[command.originStack];
        var destinyStack: *CratePile = &storage.items[command.destinyStack];
        const cratesToMove = @min(command.countCrates, originStack.items.len);
        for (1..cratesToMove + 1) |i| {
            const stackSize = originStack.items.len;
            const crateID = (stackSize - 1) - (cratesToMove - i);
            const crate = originStack.orderedRemove(crateID);
            try destinyStack.append(crate);
        }
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

    var storage = try getStacks(allocator, lines);
    defer cleanStorage(storage);

    var commandList = try getCommands(allocator, lines);
    defer cleanCommandList(commandList);

    //Exercise 0
    //try executeCommands(storage, commandList);
    //printTopStack(storage);

    //Exercise 1
    try executeCommands1(storage, commandList);
    printTopStack(storage);
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
