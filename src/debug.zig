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

fn constantInstruction(name: []const u8, chunk: *c.Chunk, offset: usize) !usize {
    const stdout = std.io.getStdOut().writer();
    const constant = chunk.*.code[offset + 1];
    try stdout.print("{s:<16} {d:>4} '", .{name, constant});
    try chunk.*.constants.print(constant);
    try stdout.print("'\n", .{});
    return offset + 2;
}

fn simpleInstruction(name: []const u8, offset: usize) callconv(.Inline) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{name});
    return offset + 1;
}

pub fn disassembleInstruction(chunk: *c.Chunk, offset: usize) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d:0>4} ", .{offset});
    if (offset > 0 and chunk.*.lines[offset] == chunk.*.lines[offset - 1]) {
        try stdout.print("   | ", .{});
    }
    else {
        try stdout.print("{d:0>4} ", .{chunk.*.lines[offset]});
    }


    var instruction = chunk.*.code[offset];
    switch (instruction) {
        @enumToInt(c.OpCode.OP_CONSTANT) => return constantInstruction("OP_CONSTANT", chunk, offset),
        @enumToInt(c.OpCode.OP_RETURN) => return simpleInstruction("OP_RETURN", offset),
        else => {
            try stdout.print("{d}\n", .{instruction});
            return offset + 1;
        }
    }
}