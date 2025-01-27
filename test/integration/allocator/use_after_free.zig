const alloc = @import("std").heap.c_allocator;

pub fn main() !u8 {
    const x_ptr: *u8 = try alloc.create(u8);
    x_ptr.* = 42;
    alloc.destroy(x_ptr);
    return x_ptr.*;
}