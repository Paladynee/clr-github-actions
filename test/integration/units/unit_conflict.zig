var _unit: [:0]const u8 = undefined; // dummy variable, but necessary for analysis
const debug = true;  // this could be set at compile time

fn set_units(value: f32, comptime unit: anytype) f32 {
  if (debug) _unit = unit;  // compiled out in non-debug builds
  return value;  // in non-"debug" builds this compiles out to an inlined nothingburger
}

fn apply_acceleration(v: f32, t: f32, comptime dist_unit: anytype) f32 {
  const acc = switch (dist_unit) {
      .m => set_units(9.8, "m/s/s"),
      .ft => set_units(32.0, "ft/s/s"),
      else => unreachable
  };
  return acc * t + v;
}

pub fn main() void {
  const t = set_units(1.0, "s");

  var v1 = set_units(10.0, "m/s"); 
  v1 = apply_acceleration(v1, t, .m);

  var v2 = set_units(10.0, "ft/s");
  v2 = apply_acceleration(v2, t, .ft);

  var v3 = v1 + v2;
  v3 = undefined;
}