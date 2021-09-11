const std = @import("std");
const c = @import("chunk.zig");
const v = @import("value.zig");
const debug = @import("debug.zig");

pub const InterpretResult = enum{
    INTERPRET_OK,
    INTERPRET_COMPILE_ERROR,
    INTERPRET_RUNTIME_ERROR,
};

const STACK_MAX = 256;

pub const VM = struct {
    chunk: *c.Chunk = undefined,
    ip: [*]u8 = undefined,
    stack: [STACK_MAX]v.Value = undefined,
    stackTop: [*]v.Value = undefined,

    pub fn init(self: *VM, allocator: *std.mem.Allocator) void {
        self.resetStack();
    }

    pub fn deinit(self: *VM, allocator: *std.mem.Allocator) void {

    }

    fn resetStack(self: *VM) void {
        self.stackTop = self.stack[0..self.stack.len];
    }

    pub fn interpret(self: *VM, chunk: *c.Chunk, debug_mode: bool) !InterpretResult {
        self.chunk = chunk;
        self.ip = self.chunk.*.code[0..self.chunk.*.count].ptr;
        return try self.run(debug_mode);
    }

    fn push(self: *VM, val: v.Value) void {
        self.stackTop.* = val;
        self.stackTop += 1;
    }

    fn pop(self: *VM) v.Value {
        self.stackTop -= 1;
        return self.stackTop[0];
    }

    fn readConstant(self: *VM, long: bool) v.Value {
        var constant: usize = undefined;
        if (long) {
            constant = 0;
            const shifts = [_]u6{0, 8, 16};
            for (shifts) |shift, index| {
                constant |= @intCast(usize, self.ip[index]) << shift;
            }
            self.ip += 3;
        }
        else {
            constant = self.ip[0];
            self.ip += 1;
        }
        return self.chunk.*.constants.values[constant];
    }

    fn binaryOp(self: *VM, opcode: c.OpCode) void {
        const b = self.pop();
        const a = self.pop();
        switch (opcode) {
            .OP_ADD => self.push(a + b),
            .OP_SUBTRACT => self.push(a - b),
            .OP_MULTIPLY => self.push(a * b),
            .OP_DIVIDE => self.push(a / b),
            else => unreachable,
        }
    }

    fn run(self: *VM, debug_mode: bool) !InterpretResult {
        const stdout = std.io.getStdOut().writer();
        while (true) {
            if (debug_mode) {
                try stdout.print("          ", .{});
                var slot: [*]v.Value = self.stack[0..self.stack.len];
                while (@ptrToInt(slot) < @ptrToInt(self.stackTop)) : (slot += 1) {
                    try stdout.print("[ {any} ]", .{slot[0]});
                }
                try stdout.print("\n", .{});

                _ = try debug.disassembleInstruction(self.chunk, @ptrToInt(&self.ip[0]) - @ptrToInt(&self.chunk.*.code[0]));
            }


            var instruction: c.OpCode = readByte: {
                const tmp = @intToEnum(c.OpCode, self.ip[0]);
                self.ip += 1;
                break :readByte tmp;
            };
            
            switch (instruction) {
                .OP_CONSTANT => {
                    var constant: v.Value = self.readConstant(false);
                    self.push(constant);
                },
                .OP_CONSTANT_LONG => {
                    var constant: v.Value = self.readConstant(true);
                    self.push(constant);
                },
                .OP_ADD, .OP_SUBTRACT, .OP_MULTIPLY, .OP_DIVIDE => {
                    self.binaryOp(instruction);
                },
                .OP_NEGATE => {
                    self.push(-self.pop());
                },
                .OP_RETURN => {
                    try stdout.print("{any}\n", .{self.pop()});
                    return .INTERPRET_OK;
                },
            }

        }
    }
};