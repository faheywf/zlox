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

fn simpleInstruction(name: []const u8, offset: usize) callconv(.Inline) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{name});
    return offset + 1;
}

pub fn disassembleInstruction(chunk: *c.Chunk, offset: usize) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d:0<4} ", .{offset});
    var instruction = chunk.*.code[offset];
    switch (instruction) {
        @enumToInt(c.OpCode.OP_RETURN) => return simpleInstruction("OP_RETURN", offset),
        else => {
            try stdout.print("{d}\n", .{instruction});
            return offset + 1;
        }
    }
}