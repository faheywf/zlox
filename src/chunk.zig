const std = @import("std");
const memory = @import("memory.zig");
const value = @import("value.zig");


pub const OpCode = enum(u8) {
    OP_CONSTANT,
    OP_RETURN,
};

pub const Chunk = struct {
    count: usize = undefined,
    capacity: usize = undefined,
    code: []u8 = undefined,
    lines: []usize = undefined,
    constants: value.ValueArray = undefined,

    pub fn init(self: *Chunk, allocator: *std.mem.Allocator) void {
        self.count = 0;
        self.capacity = 0;
        self.code = allocator.alloc(u8, 0) catch @panic("Failed to allocate memory.");
        self.lines = allocator.alloc(usize, 0) catch @panic("Failed to allocate memory.");
        self.constants = value.ValueArray{};
        self.constants.init(allocator);
    }

    pub fn write(self: *Chunk, allocator: *std.mem.Allocator, byte: u8, line: usize) void {
        if (self.capacity < self.count + 1) {
            var old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.code = memory.growArray(allocator, u8, self.code, old_capacity, self.capacity);
            self.lines = memory.growArray(allocator, usize, self.lines, old_capacity, self.capacity);
        }
        self.code[self.count] = byte;
        self.lines[self.count] = line;
        self.count += 1;
    }

    pub fn addConst(self: *Chunk, allocator: *std.mem.Allocator, val: value.Value) usize {
        self.constants.write(allocator, val);
        return self.constants.count - 1;
    }

    pub fn free(self: *Chunk, allocator: *std.mem.Allocator) void {
        memory.freeArray(allocator, u8, self.code, self.capacity);
        memory.freeArray(allocator, usize, self.lines, self.capacity);
        self.constants.free(allocator);
        self.init(allocator);
    }
};