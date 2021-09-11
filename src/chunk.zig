const std = @import("std");
const memory = @import("memory.zig");


pub const OpCode = enum(u8) {
    OP_RETURN,
};

pub const Chunk = struct {
    count: usize = undefined,
    capacity: usize = undefined,
    code: []u8 = undefined,

    pub fn init(self: *Chunk, allocator: *std.mem.Allocator) void {
        self.count = 0;
        self.capacity = 0;
        self.code = allocator.alloc(u8, 0) catch @panic("Failed to allocate memory.");
    }

    pub fn write(self: *Chunk, allocator: *std.mem.Allocator, byte: u8) void {
        if (self.capacity < self.count + 1) {
            var old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.code = memory.growArray(allocator, u8, self.code, old_capacity, self.capacity);
        }
        self.code[self.count] = byte;
        self.count += 1;
    }

    pub fn free(self: *Chunk, allocator: *std.mem.Allocator) void {
        memory.freeArray(allocator, u8, self.code, self.capacity);
        self.init(allocator);
    }
};