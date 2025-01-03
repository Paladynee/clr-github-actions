const alloc = @import("std").heap.c_allocator;

fn function_now_manages(x_ptr: *u8) void {
    alloc.destroy(x_ptr);
}

pub fn main() !void {
    const x_ptr: *u8 = try alloc.create(u8);
    function_now_manages(x_ptr);
    alloc.destroy(x_ptr);
}