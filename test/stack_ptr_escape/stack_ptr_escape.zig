fn escaped_ptr() *u32 {
  var foo: u32 = 0;
  foo += 1;
  return &foo; 
}

pub fn main() void {
    const x_ptr: *u32 = escaped_ptr();
    _ = x_ptr.*;
}