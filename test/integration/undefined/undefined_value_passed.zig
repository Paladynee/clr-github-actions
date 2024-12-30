fn deref_ptr(ptr: *u32) u32 {
  return ptr.*; 
}

pub fn main() void {
    var x: u32 = undefined;
    _ = deref_ptr(&x);
}