const alloc = @import("std").heap.c_allocator;

pub fn do_nothing(pointer: *u8) *u8 {
    return pointer;
}

pub fn main() !void {
    var x_ptr: *u8 = try alloc.create(u8);
    alloc.destroy(x_ptr);
    x_ptr = do_nothing(x_ptr);
}