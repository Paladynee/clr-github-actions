const alloc = @import("std").heap.c_allocator;

pub fn main() !void {
  _ = try alloc.create(u8);
  return;
}