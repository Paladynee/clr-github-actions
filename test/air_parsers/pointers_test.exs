defmodule ClrTest.AirParsers.PointersTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "pointer operations" do
    alias Clr.Air.Instruction.Pointers.Op

    test "ptr_add" do
      assert %Op{
               op: :add,
               type: {:ptr, :many, ~l"usize", []},
               src: {0, :keep},
               val: ~l"@Air.Inst.Ref.zero_usize"
             } =
               Instruction.parse("ptr_add([*]usize, %0, @Air.Inst.Ref.zero_usize)")
    end

    test "ptr_sub" do
      assert %Op{
               op: :sub,
               type: {:ptr, :many, ~l"usize", []},
               src: {0, :keep},
               val: ~l"@Air.Inst.Ref.zero_usize"
             } =
               Instruction.parse("ptr_sub([*]usize, %0, @Air.Inst.Ref.zero_usize)")
    end
  end

  test "struct_field_ptr"

  alias Clr.Air.Instruction.Pointers.StructFieldPtrIndex

  test "struct_field_ptr_index_0" do
    assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 0} =
             Instruction.parse("struct_field_ptr_index_0(*u32, %0)")
  end

  test "struct_field_ptr_index_1" do
    assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 1} =
             Instruction.parse("struct_field_ptr_index_1(*u32, %0)")
  end

  test "struct_field_ptr_index_2" do
    assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 2} =
             Instruction.parse("struct_field_ptr_index_2(*u32, %0)")
  end

  test "struct_field_ptr_index_3" do
    assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 3} =
             Instruction.parse("struct_field_ptr_index_3(*u32, %0)")
  end

  alias Clr.Air.Instruction.Pointers.Slice

  test "slice" do
    assert %Slice{type: ~l"usize", src: {0, :keep}, len: {2, :clobber}} =
             Instruction.parse("slice(usize, %0, %2!)")
  end

  alias Clr.Air.Instruction.Pointers.SlicePtr

  test "slice_ptr" do
    assert %SlicePtr{type: ~l"usize", src: {0, :keep}} =
             Instruction.parse("slice_ptr(usize, %0)")
  end

  alias Clr.Air.Instruction.Pointers.SliceLen

  test "slice_len" do
    assert %SliceLen{type: ~l"usize", src: {0, :keep}} =
             Instruction.parse("slice_len(usize, %0)")
  end

  alias Clr.Air.Instruction.Pointers.PtrSlicePtrPtr

  test "ptr_slice_ptr_ptr" do
    assert %PtrSlicePtrPtr{
             type: {:ptr, :slice, {:ptr, :one, ~l"u8", []}, []},
             src: {13, :clobber}
           } =
             Instruction.parse("ptr_slice_ptr_ptr([]*u8, %13!)")
  end

  alias Clr.Air.Instruction.Pointers.PtrSliceLenPtr

  test "ptr_slice_len_ptr" do
    assert %PtrSliceLenPtr{type: {:ptr, :one, {:lvalue, ["usize"]}, []}, src: {20, :clobber}} =
             Instruction.parse("ptr_slice_len_ptr(*usize, %20!)")
  end
end
