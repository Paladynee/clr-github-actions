defmodule ClrTest.AirParsers.MemTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Mem.Alloc

  test "alloc" do
    assert %Alloc{type: {:ptr, :one, ~l"usize", []}} = Instruction.parse("alloc(*usize)")
  end

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

  alias Clr.Air.Instruction.Mem.GetUnionTag

  test "get_union_tag" do
    assert %GetUnionTag{src: {298, :keep}, type: {:lvalue, _}} =
             Instruction.parse(
               "get_union_tag(@typeInfo(debug.Dwarf.readEhPointer__union_4486).@\"union\".tag_type.?, %298)"
             )
  end

  alias Clr.Air.Instruction.Mem.Set

  test "memset" do
    assert %Set{src: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8", safe: false} =
             Instruction.parse("memset(%0, @Air.Inst.Ref.zero_u8)")
  end

  test "memset_safe" do
    assert %Set{src: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8", safe: true} =
             Instruction.parse("memset_safe(%0, @Air.Inst.Ref.zero_u8)")
  end

  alias Clr.Air.Instruction.Mem.Cpy

  test "memcpy" do
    assert %Cpy{loc: {104, :clobber}, val: {112, :clobber}} =
             Instruction.parse("memcpy(%104!, %112!)")
  end

  alias Clr.Air.Instruction.Mem.TagName

  test "tag_name" do
    assert %TagName{src: {39, :clobber}} = Instruction.parse("tag_name(%39!)")
  end

  alias Clr.Air.Instruction.Mem.ErrorName

  test "error_name" do
    assert %ErrorName{src: {39, :clobber}} = Instruction.parse("error_name(%39!)")
  end

  alias Clr.Air.Instruction.Mem.AggregateInit

  test "aggregate_init" do
    assert %AggregateInit{} =
             Instruction.parse(
               "aggregate_init(struct { comptime @Type(.enum_literal) = .mmap, comptime usize = 0, usize, comptime usize = 3, comptime u32 = 34, comptime usize = 18446744073709551615, comptime u64 = 0 }, [<@Type(.enum_literal), .mmap>, @Air.Inst.Ref.zero_usize, %44!, <usize, 3>, <u32, 34>, <usize, 18446744073709551615>, <u64, 0>])"
             )
  end

  alias Clr.Air.Instruction.Mem.UnionInit

  test "union_init" do
    assert %UnionInit{index: 0, src: {18, :clobber}} = Instruction.parse("union_init(0, %18!)")
  end

  test "prefetch"
end
