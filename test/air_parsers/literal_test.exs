defmodule ClrTest.Air.LiteralTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  test "generic literal"

  test "integer literal" do
    assert {:literal, "usize", 8} = Type.parse_literal("<usize, 8>")
  end

  test "negative integer literal" do
    assert {:literal, "usize", -8} = Type.parse_literal("<usize, -8>")
  end

  test "generic function literal" do
    assert {:literal, {:fn, [{:ptr, :slice, "elf.Elf64_Phdr"}], "void", []},
            {:function, "initStatic"}} =
             Type.parse_literal("<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>")
  end

  test "const * function literal" do
    assert {:literal, {:fn, [], "noreturn", [callconv: :naked]}, "start._start"} =
             Type.parse_literal("<*const fn () callconv(.naked) noreturn, start._start>")
  end

  test "with @as and @ptrCast" do
    assert {:literal, _, {:as, _, _}} =
             Type.parse_literal(
               "<?[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_start))>"
             )
  end

  test "complex function literal" do
    assert {:literal, {:fn, ["usize", _, _], "u8", [callconv: :inline]},
            {:function, "callMainWithArgs"}} =
             Type.parse_literal(
               "<fn (usize, [*][*:0]u8, [][*:0]u8) callconv(.@\"inline\") u8, (function 'callMainWithArgs')>"
             )
  end

  test "map literal" do
    assert {:literal, "os.linux.MAP__struct_2035", {:map, _}} =
             Type.parse_literal(
               "<os.linux.MAP__struct_2035, .{ .TYPE = .PRIVATE, .FIXED = false, .ANONYMOUS = true, .@\"32BIT\" = false, ._7 = 0, .GROWSDOWN = false, ._9 = 0, .DENYWRITE = false, .EXECUTABLE = false, .LOCKED = false, .NORESERVE = false, .POPULATE = false, .NONBLOCK = false, .STACK = false, .HUGETLB = false, .SYNC = false, .FIXED_NOREPLACE = false, ._21 = 0, .UNINITIALIZED = false, .@\"_\" = 0 }>"
             )
  end

  test "string literal" do
    assert {:literal, {:ptr, :slice, "u8", [const: true]}, {:string, "integer overflow", 0..16}} =
             Type.parse_literal("<[]const u8, \"integer overflow\"[0..16]>")
  end
end
