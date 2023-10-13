const std = @import("std");
const ArrayList = std.ArrayList;

const Matrix = struct {
    data: ArrayList(ArrayList(u8)),
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,

    pub fn init(ally: std.mem.Allocator, x: u32, y: u32) !Matrix {
        var result = Matrix{
            .data = undefined,
            .allocator = ally,
            .width = x,
            .height = y,
        };
        result.data = ArrayList(ArrayList(u8)).init(result.allocator);
        for (0..x) |xi| {
            try result.data.append(ArrayList(u8).init(result.allocator));
            for (0..y) |_| {
                try result.data.items[xi].append(0);
            }
        }

        return result;
    }

    pub fn deinit(self: *Matrix) void {
        for (0..self.width) |x| {
            self.data.items[x].deinit();
        }
        self.data.deinit();
    }

    pub fn get(self: *const Matrix, x: u32, y: u32) u8 {
        return self.data.items[x].items[y];
    }

    pub fn set(self: *Matrix, x: u32, y: u32, data: u8) void {
        self.data.items[x].items[y] = data;
    }

    pub fn print(self: *const Matrix) void {
        for (0..self.width) |x| {
            std.debug.print("\n", .{});
            for (0..self.height) |y| {
                std.debug.print("{}", .{self.data.items[x].items[y]});
            }
        }
        std.debug.print("\n", .{});
    }
};

pub fn createMatrix(ally: std.mem.Allocator, lines: ArrayList([]u8)) !Matrix {
    const width = lines.items.len;
    const height = lines.items[0].len;
    var matrix = try Matrix.init(ally, @intCast(width), @intCast(height));
    for (0..matrix.width) |x| {
        for (0..matrix.height) |y| {
            const value = lines.items[x][y] - '0';
            matrix.set(@intCast(x), @intCast(y), value);
        }
    }

    return matrix;
}

pub fn computeVisibilityMatrix(heightMap: Matrix) !Matrix {
    var visibilityMatrix = try Matrix.init(heightMap.allocator, heightMap.width, heightMap.height);
    for (0..visibilityMatrix.width) |xi| {
        for (0..visibilityMatrix.height) |yi| {
            const x: u32 = @intCast(xi);
            const y: u32 = @intCast(yi);
            if (xi == 0 or xi == visibilityMatrix.width - 1 or yi == 0 or yi == visibilityMatrix.height - 1) {
                visibilityMatrix.set(x, y, 1);
                continue;
            }
            const height = heightMap.get(x, y);

            // To left
            var isVisible = true;
            var lx: i32 = @intCast(x);
            lx -= 1;
            while (lx >= 0) : (lx -= 1) {
                if (heightMap.get(@intCast(lx), y) >= height) {
                    isVisible = isVisible and false;
                }
            }
            if (isVisible) {
                visibilityMatrix.set(x, y, 1);
                continue;
            }

            // To right
            isVisible = true;
            lx = @intCast(x);
            lx += 1;
            while (lx < heightMap.width) : (lx += 1) {
                if (heightMap.get(@intCast(lx), y) >= height) {
                    isVisible = isVisible and false;
                }
            }
            if (isVisible) {
                visibilityMatrix.set(x, y, 1);
                continue;
            }

            // To top
            isVisible = true;
            var ly: i32 = @intCast(y);
            ly += 1;
            while (ly < heightMap.height) : (ly += 1) {
                if (heightMap.get(x, @intCast(ly)) >= height) {
                    isVisible = isVisible and false;
                }
            }
            if (isVisible) {
                visibilityMatrix.set(x, y, 1);
                continue;
            }

            // To bottom
            isVisible = true;
            ly = @intCast(y);
            ly -= 1;
            while (ly >= 0) : (ly -= 1) {
                if (heightMap.get(x, @intCast(ly)) >= height) {
                    isVisible = isVisible and false;
                }
            }
            if (isVisible) {
                visibilityMatrix.set(x, y, 1);
                continue;
            }
        }
    }

    return visibilityMatrix;
}

pub fn computeVisibleCount(visibilityMatrix: Matrix) u32 {
    var result: u32 = 0;
    for (0..visibilityMatrix.width) |x| {
        for (0..visibilityMatrix.height) |y| {
            if (visibilityMatrix.get(@intCast(x), @intCast(y)) == 1) {
                result += 1;
            }
        }
    }

    return result;
}

pub fn computeMaxScenery(heightMap: Matrix, visibilityMatrix: Matrix) u32 {
    var maxScenery: u32 = 0;
    for (0..visibilityMatrix.width) |xi| {
        for (0..visibilityMatrix.height) |yi| {
            if (xi == 0 or xi == visibilityMatrix.width - 1 or yi == 0 or yi == visibilityMatrix.height - 1) {
                continue;
            }

            const x: u32 = @intCast(xi);
            const y: u32 = @intCast(yi);
            var sceneryTop: u32 = 0;
            var sceneryBottom: u32 = 0;
            var sceneryLeft: u32 = 0;
            var sceneryRight: u32 = 0;
            const height = heightMap.get(x, y);

            // To left
            var lx: i32 = @intCast(x);
            lx -= 1;
            while (lx >= 0) : (lx -= 1) {
                sceneryLeft += 1;
                if (heightMap.get(@intCast(lx), y) >= height) {
                    break;
                }
            }

            // To right
            lx = @intCast(x);
            lx += 1;
            while (lx < heightMap.width) : (lx += 1) {
                sceneryRight += 1;
                if (heightMap.get(@intCast(lx), y) >= height) {
                    break;
                }
            }

            // To top
            var ly: i32 = @intCast(y);
            ly += 1;
            while (ly < heightMap.height) : (ly += 1) {
                sceneryTop += 1;
                if (heightMap.get(x, @intCast(ly)) >= height) {
                    break;
                }
            }

            // To bottom
            ly = @intCast(y);
            ly -= 1;
            while (ly >= 0) : (ly -= 1) {
                sceneryBottom += 1;
                if (heightMap.get(x, @intCast(ly)) >= height) {
                    break;
                }
            }

            const currentScenery = sceneryTop * sceneryBottom * sceneryLeft * sceneryRight;
            maxScenery = @max(maxScenery, currentScenery);
        }
    }

    return maxScenery;
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

    var matrix = try createMatrix(allocator, lines);
    defer matrix.deinit();

    var visibilityMatrix = try computeVisibilityMatrix(matrix);
    defer visibilityMatrix.deinit();

    const result0 = computeVisibleCount(visibilityMatrix);
    std.debug.print("\nResult 0: {}\n", .{result0});

    const result1 = computeMaxScenery(matrix, visibilityMatrix);
    std.debug.print("\nResult 1: {}\n", .{result1});
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
