const alloc = @import("std").heap.c_allocator;

pub fn main() !u8 {
    var x: u8 = undefined;
    alloc.destroy(&x);
    x += 1;
    return x;
}