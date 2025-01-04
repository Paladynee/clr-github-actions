const alloc1 = @import("std").heap.page_allocator;
const alloc2 = @import("std").heap.c_allocator;

pub fn main() !void {
    const x_ptr: *u8 = try alloc1.create(u8);
    alloc2.destroy(x_ptr);
}