const alloc = @import("std").heap.c_allocator;

fn allocate_for_me() !*u8 {
  return alloc.create(u8);
}

pub fn main() !void {
  _ = try allocate_for_me();
}