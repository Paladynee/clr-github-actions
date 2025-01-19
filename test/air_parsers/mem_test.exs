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

  alias Clr.Air.Instruction.Mem.Memset

  test "memset" do
    assert %Memset{src: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8"} =
             Instruction.parse("memset(%0, @Air.Inst.Ref.zero_u8)")
  end

  test "memset_safe" do
    assert %Memset{src: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8", safe: true} =
             Instruction.parse("memset_safe(%0, @Air.Inst.Ref.zero_u8)")
  end

  alias Clr.Air.Instruction.Mem.TagName

  test "tag_name" do
    assert %TagName{src: {39, :clobber}} = Instruction.parse("tag_name(%39!)")
  end

  alias Clr.Air.Instruction.Mem.ErrorName

  test "error_name" do
    assert %ErrorName{src: {39, :clobber}} = Instruction.parse("error_name(%39!)")
  end
  
  test "aggregate_init"

  test "union_init"

  test "prefetch"
end
