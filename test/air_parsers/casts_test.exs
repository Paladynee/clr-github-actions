defmodule ClrTest.AirParsers.CastsTest do
  use ExUnit.Case, async: true

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction
  alias Clr.Air.Instruction.Casts.Bitcast

  test "bitcast" do
    assert %Bitcast{type: {:ptr, :many, ~l"elf.Elf64_auxv_t", []}, src: {65, :clobber}} =
             Instruction.parse("bitcast([*]elf.Elf64_auxv_t, %65!)")
  end

  alias Clr.Air.Instruction.Casts.IntFromPtr

  test "int_from_ptr" do
    assert %IntFromPtr{src: {:literal, ptrtyp, {:as, ptrtyp, {:ptrcast, ~l"__init_array_end"}}}} =
             Instruction.parse(
               "int_from_ptr(<[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_end))>)"
             )
  end

  alias Clr.Air.Instruction.Casts.IntFromBool

  test "int_from_bool" do
    assert %IntFromBool{src: {218, :clobber}} = Instruction.parse("int_from_bool(%218!)")
  end
end
