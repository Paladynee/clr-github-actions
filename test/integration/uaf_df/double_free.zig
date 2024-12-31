const alloc = @import("std").heap.c_allocator;

pub fn main() !void {
    const x_ptr: *u8 = try alloc.create(u8);
    alloc.destroy(x_ptr);
    alloc.destroy(x_ptr);
}