defmodule ClrTest.AirParsers.MemTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Mem.Load

  test "load" do
    assert %Load{type: {:ptr, :many, ~l"usize", []}, src: {19, :keep}} =
             Instruction.parse("load([*]usize, %19)")
  end

  alias Clr.Air.Instruction.Mem.Store

  describe "store" do
    test "basic" do
      assert %Store{src: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store(%19, @Air.Inst.Ref.zero_usize)")
    end

    # note that the "safe" extension changes nothing for "Store".
    test "safe" do
      assert %Store{src: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store_safe(%19, @Air.Inst.Ref.zero_usize)")
    end
  end

  alias Clr.Air.Instruction.Mem.StructFieldVal

  test "struct_field_val" do
    assert %StructFieldVal{src: {93, :clobber}, index: 0} =
             Instruction.parse("struct_field_val(%93!, 0)")
  end

  alias Clr.Air.Instruction.Mem.SetUnionTag

  test "set_union_tag" do
    assert %SetUnionTag{src: {14, :keep}, val: {:literal, _, _}} =
             Instruction.parse(
               "set_union_tag(%14, <@typeInfo(debug.Dwarf.readEhPointer__union_4486).@\"union\".tag_type.?, .unsigned>)"
             )
  end

  test "get_union_tag"
end
