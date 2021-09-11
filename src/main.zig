const std = @import("std");
const expect = std.testing.expect;
const c = @import("chunk.zig");
const debug = @import("debug.zig");


pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("TEST FAIL"); //fail test; can't try in defer as defer is executed after we return
    }
    var allocator = &gpa.allocator;

    // do  lox stuff in here
    var chunk = c.Chunk{};
    chunk.init(allocator);

    chunk.writeConst(allocator, 1.2, 123);

    chunk.write(allocator, @enumToInt(c.OpCode.OP_RETURN), 123);

    try debug.disassembleChunk(&chunk, "test chunk");
    chunk.free(allocator);
    
    
    
    
}
