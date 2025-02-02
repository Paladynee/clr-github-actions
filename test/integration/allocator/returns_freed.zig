const alloc = @import("std").heap.c_allocator;

pub fn returns_freed() !*u8 {
    const pointer = try alloc.create(u8);
    alloc.destroy(pointer);
    return pointer;
}

pub fn main() !void {
    _ = try returns_freed();
}