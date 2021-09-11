const std = @import("std");
const memory = @import("memory.zig");
const value = @import("value.zig");


pub const OpCode = enum(u8) {
    OP_CONSTANT,
    OP_CONSTANT_LONG,
    OP_ADD,
    OP_SUBTRACT,
    OP_MULTIPLY,
    OP_DIVIDE,
    OP_NEGATE,
    OP_RETURN,
};

const Line = struct {
    offset: usize,
    line: usize
};

pub const Chunk = struct {
    count: usize = undefined,
    capacity: usize = undefined,
    code: []u8 = undefined,
    line_count: usize = undefined,
    line_capacity: usize = undefined,
    lines: []Line = undefined,
    constants: value.ValueArray = undefined,

    pub fn init(self: *Chunk, allocator: *std.mem.Allocator) void {
        self.count = 0;
        self.capacity = 0;
        self.code = allocator.alloc(u8, 0) catch @panic("Failed to allocate memory.");
        self.line_count = 0;
        self.line_capacity = 0;
        self.lines = allocator.alloc(Line, 0) catch @panic("Failed to allocate memory.");
        self.constants = value.ValueArray{};
        self.constants.init(allocator);
    }

    pub fn write(self: *Chunk, allocator: *std.mem.Allocator, byte: u8, line: usize) void {
        if (self.capacity < self.count + 1) {
            var old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.code = memory.growArray(allocator, u8, self.code, old_capacity, self.capacity);
        }
        self.code[self.count] = byte;
        self.count += 1;

        // See if we're on the same line
        if (self.line_count > 0 and self.lines[self.line_count - 1].line == line){
            return;
        }

        // Start new line
        if (self.line_capacity < self.line_count + 1) {
            var old_line_capacity = self.line_capacity;
            self.line_capacity = memory.growCapacity(old_line_capacity);
            self.lines = memory.growArray(allocator, Line, self.lines, old_line_capacity, self.line_capacity);
        }

        self.lines[self.line_count] = Line{.offset=self.count - 1, .line=line};
        self.line_count += 1;
    }

    pub fn writeConst(self: *Chunk, allocator: *std.mem.Allocator, val: value.Value, line: usize) void {
        const constant = self.addConst(allocator, val);
        if (constant < 256) {
            self.write(allocator, @enumToInt(OpCode.OP_CONSTANT), line);
            self.write(allocator, @intCast(u8, constant), line);
        }
        else { // support up to 24 bits of constants
            self.write(allocator, @enumToInt(OpCode.OP_CONSTANT_LONG), line);
            const shifts = [_]u6{0, 8, 16};
            for (shifts) |shift| {
                self.write(allocator, @intCast(u8, constant >> shift & 0xF), line);
            }
        }
    }

    fn addConst(self: *Chunk, allocator: *std.mem.Allocator, val: value.Value) usize {
        self.constants.write(allocator, val);
        return self.constants.count - 1;
    }

    pub fn deinit(self: *Chunk, allocator: *std.mem.Allocator) void {
        memory.freeArray(allocator, u8, self.code, self.capacity);
        memory.freeArray(allocator, Line, self.lines, self.line_capacity);
        self.constants.deinit(allocator);
        self.init(allocator);
    }

    pub fn getLine(self: *Chunk, instruction: usize) usize {
        var start: usize = 0;
        var end = self.line_count - 1;

        while (true) {
            var mid = (start + end) / 2;
            var line = &self.lines[mid];
            if (instruction < line.*.offset) {
                end = mid - 1;
            }
            else {
                if (mid == self.line_count - 1 or instruction < self.lines[mid + 1].offset) {
                    return line.*.line;
                }
                else {
                    start = mid + 1;
                }
            }
        }
    }
};