const std = @import("std");



pub fn growCapacity(capacity: usize) usize {
    return if (capacity < 8) 8 else capacity * 2;
}

pub fn growArray(allocator: *std.mem.Allocator, comptime T: type, pointer: []T, old_count: usize, new_count: usize) []T {
    return reallocate(allocator, T, pointer, @sizeOf(T) * old_count, @sizeOf(T) * new_count);
}

pub fn freeArray(allocator: *std.mem.Allocator, comptime T: type, pointer: []T, capacity: usize) void {
    _ = reallocate(allocator, T, pointer, @sizeOf(T) * capacity, 0);
}

pub fn reallocate(allocator: *std.mem.Allocator, comptime T: type, pointer: []T, old_size: usize, new_size: usize) []T {
    var result = allocator.realloc(pointer, new_size) catch @panic("Failed to allocate memory.");
    return result;
}