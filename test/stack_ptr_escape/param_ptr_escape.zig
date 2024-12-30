fn escaped_param_ptr(param: u32) *const u32 {
  return &param; 
}

pub fn main() void {
    const x_ptr: *const u32 = escaped_param_ptr(20);
    _ = x_ptr.*;
}