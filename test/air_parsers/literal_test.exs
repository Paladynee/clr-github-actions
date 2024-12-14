defmodule ClrTest.Air.LiteralTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  test "generic literal"

  test "integer literal" do
    assert {:literal, "usize", 8} = Type.parse_literal("<usize, 8>")
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
end
