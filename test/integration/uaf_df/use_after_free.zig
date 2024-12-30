const alloc = @import("std").heap.c_allocator;

pub fn main() void {
    const x_ptr: *u8 = alloc.create(u8);
    alloc.destroy(x_ptr);
    return x_ptr.*;
}