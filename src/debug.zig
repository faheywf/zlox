const std = @import("std");
const c = @import("chunk.zig");


pub fn disassembleChunk(chunk: *c.Chunk, name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("== {s} ==\n", .{name});
    var offset: usize = 0;
    while (offset < chunk.*.count) {
        offset = try disassembleInstruction(chunk, offset);
    }
}

fn constantInstruction(name: []const u8, chunk: *c.Chunk, offset: usize, long: bool) !usize {
    const stdout = std.io.getStdOut().writer();
    var constant: usize = undefined;
    if (long) {
        constant = 0;
        const shifts = [_]u6{0, 8, 16};
        for (shifts) |shift, index| {
            constant |= @intCast(usize, chunk.*.code[offset + 1 + index]) << shift;
        }
    }
    else {
        constant = chunk.*.code[offset + 1];
    }
    try stdout.print("{s:<16} {d:>4} '", .{name, constant});
    try chunk.*.constants.print(constant);
    try stdout.print("'\n", .{});
    if (long) {
        return offset + 4;
    }
    else {
        return offset + 2;
    }
}

fn simpleInstruction(name: []const u8, offset: usize) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{name});
    return offset + 1;
}

pub fn disassembleInstruction(chunk: *c.Chunk, offset: usize) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d:0>4} ", .{offset});
    var line = chunk.getLine(offset);
    if (offset > 0 and line == chunk.getLine(offset - 1)) {
        try stdout.print("   | ", .{});
    }
    else {
        try stdout.print("{d:0>4} ", .{line});
    }


    var instruction = @intToEnum(c.OpCode, chunk.*.code[offset]);
    switch (instruction) {
        .OP_CONSTANT => return constantInstruction("OP_CONSTANT", chunk, offset, false),
        .OP_CONSTANT_LONG => return constantInstruction("OP_CONSTANT_LONG", chunk, offset, true),
        .OP_ADD => return simpleInstruction("OP_ADD", offset),
        .OP_SUBTRACT => return simpleInstruction("OP_SUBTRACT", offset),
        .OP_MULTIPLY => return simpleInstruction("OP_MULTIPLY", offset),
        .OP_DIVIDE => return simpleInstruction("OP_DIVIDE", offset),
        .OP_NEGATE => return simpleInstruction("OP_NEGATE", offset),
        .OP_RETURN => return simpleInstruction("OP_RETURN", offset),
    }
}