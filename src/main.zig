const std = @import("std");
const expect = std.testing.expect;
const c = @import("chunk.zig");
const debug = @import("debug.zig");
const vm = @import("vm.zig");


pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("TEST FAIL"); //fail test; can't try in defer as defer is executed after we return
    }
    var allocator = &gpa.allocator;

    // do  lox stuff in here
    var virtual_machine = vm.VM{};
    virtual_machine.init(allocator);
    defer virtual_machine.deinit(allocator);

    var chunk = c.Chunk{};
    chunk.init(allocator);
    defer chunk.deinit(allocator);

    chunk.writeConst(allocator, 1.2, 123);
    chunk.writeConst(allocator, 3.4, 123);
    chunk.write(allocator, @enumToInt(c.OpCode.OP_ADD), 123);
    chunk.writeConst(allocator, 5.6, 123);
    chunk.write(allocator, @enumToInt(c.OpCode.OP_DIVIDE), 123);
    chunk.write(allocator, @enumToInt(c.OpCode.OP_NEGATE), 123);
    chunk.write(allocator, @enumToInt(c.OpCode.OP_RETURN), 123);

    _ = try virtual_machine.interpret(&chunk, false);


    
}
