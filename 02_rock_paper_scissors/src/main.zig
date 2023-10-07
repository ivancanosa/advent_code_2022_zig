const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

const Play = enum {
    Rock,
    Scissors,
    Paper,
};

fn getPlay(char: u8) Play {
    return switch (char) {
        'A', 'X' => Play.Rock,
        'B', 'Y' => Play.Paper,
        'C', 'Z' => Play.Scissors,
        else => unreachable,
    };
}

fn getWinnablePlay(adversaryPlay: Play) Play {
    return switch (adversaryPlay) {
        Play.Rock => Play.Paper,
        Play.Scissors => Play.Rock,
        Play.Paper => Play.Scissors,
    };
}

fn getPlayScore(play: Play) u8 {
    return switch (play) {
        Play.Rock => 1,
        Play.Paper => 2,
        Play.Scissors => 3,
    };
}

fn getOutcomeScore(adversaryPlay: Play, playerPlay: Play) u8 {
    if (adversaryPlay == playerPlay) {
        return 3;
    }
    if (playerPlay == getWinnablePlay(adversaryPlay)) {
        return 6;
    }
    return 0;
}

fn getRoundScore(adversaryPlay: Play, playerPlay: Play) u32 {
    const playScore = getPlayScore(playerPlay);
    const outcomeScore = getOutcomeScore(adversaryPlay, playerPlay);
    return playScore + outcomeScore;
}

// Exercise 1

fn getRoundPlays(str: []const u8) [2]Play {
    var it = std.mem.split(u8, str, " ");
    var plays: [2]Play = undefined;
    var i: u32 = 0;
    while (it.next()) |substr| : (i += 1) {
        plays[i] = getPlay(substr[0]);
    }
    return plays;
}

fn ex0(lines: ArrayList([]u8)) u32 {
    var score: u32 = 0;
    for (lines.items) |line| {
        if (!isEmptyStr(line)) {
            const plays = getRoundPlays(line);
            score += getRoundScore(plays[0], plays[1]);
        }
    }
    return score;
}

// Exercise 2

const RoundOutcome = enum {
    Lose,
    Win,
    Draw,
};

fn getOutcome(char: u8) RoundOutcome {
    return switch (char) {
        'X' => RoundOutcome.Lose,
        'Y' => RoundOutcome.Draw,
        'Z' => RoundOutcome.Win,
        else => unreachable,
    };
}

const RoundData = struct {
    adversaryPlay: Play,
    roundOutcome: RoundOutcome,
};

fn getLossingPlay(adversaryPlay: Play) Play {
    return switch (adversaryPlay) {
        Play.Rock => Play.Scissors,
        Play.Scissors => Play.Paper,
        Play.Paper => Play.Rock,
    };
}

fn getPlayerPlay(roundData: RoundData) Play {
    if (roundData.roundOutcome == RoundOutcome.Draw) {
        return roundData.adversaryPlay;
    }
    if (roundData.roundOutcome == RoundOutcome.Win) {
        return getWinnablePlay(roundData.adversaryPlay);
    }
    return getLossingPlay(roundData.adversaryPlay);
}

fn getRoundData(str: []const u8) RoundData {
    var it = std.mem.split(u8, str, " ");
    var i: u32 = 0;
    var round: RoundData = undefined;
    while (it.next()) |substr| : (i += 1) {
        if (i == 0) {
            round.adversaryPlay = getPlay(substr[0]);
        } else {
            round.roundOutcome = getOutcome(substr[0]);
        }
    }
    return round;
}

fn ex1(lines: ArrayList([]u8)) u32 {
    var score: u32 = 0;
    for (lines.items) |line| {
        if (!isEmptyStr(line)) {
            const roundData = getRoundData(line);
            const playerPlay = getPlayerPlay(roundData);
            score += getRoundScore(roundData.adversaryPlay, playerPlay);
        }
    }
    return score;
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

    const ex0_score = ex0(lines);
    const ex1_score = ex1(lines);
    std.debug.print("Ex0 score: {}\n", .{ex0_score});
    std.debug.print("Ex1 score: {}\n", .{ex1_score});
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
