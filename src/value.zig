const std = @import("std");
const memory = @import("memory.zig");

pub const Value = f64;

pub const ValueArray = struct {
    count: usize = undefined,
    capacity: usize = undefined,
    values: []Value = undefined,

    pub fn init(self: *ValueArray, allocator: *std.mem.Allocator) void {
        self.count = 0;
        self.capacity = 0;
        self.values = allocator.alloc(Value, 0) catch @panic("Failed to allocate memory.");
    }

    pub fn write(self: *ValueArray, allocator: *std.mem.Allocator, value: Value) void {
        if (self.capacity < self.count + 1) {
            var old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.values = memory.growArray(allocator, Value, self.values, old_capacity, self.capacity);
        }
        self.values[self.count] = value;
        self.count += 1;
    }

    pub fn deinit(self: *ValueArray, allocator: *std.mem.Allocator) void {
        memory.freeArray(allocator, Value, self.values, self.capacity);
        self.init(allocator);
    }

    pub fn print(self: *ValueArray, index: usize) !void {
        const stdout = std.io.getStdOut().writer();
        const value = self.values[index];
        try stdout.print("{any}", .{value});
    }
};