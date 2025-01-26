defmodule ClrTest.AirParsers.PointersTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction
  alias ClrTest.TestAir

  import Clr.Air.Lvalue

  describe "pointer operations" do
    alias Clr.Air.Instruction.Pointer.Op

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

  alias Clr.Air.Instruction.Pointer.StructFieldPtr

  test "struct_field_ptr" do
    assert %StructFieldPtr{
             src: {0, :keep},
             index: 2
           } =
             Instruction.parse("struct_field_ptr(%0, 2)")
  end

  alias Clr.Air.Instruction.Pointer.StructFieldPtrIndex

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

  alias Clr.Air.Instruction.Pointer.Slice

  test "slice" do
    assert %Slice{type: ~l"usize", src: {0, :keep}, len: {2, :clobber}} =
             Instruction.parse("slice(usize, %0, %2!)")
  end

  alias Clr.Air.Instruction.Pointer.SlicePtr

  test "slice_ptr" do
    assert %SlicePtr{type: ~l"usize", src: {0, :keep}} =
             Instruction.parse("slice_ptr(usize, %0)")
  end

  alias Clr.Air.Instruction.Pointer.SliceLen

  test "slice_len" do
    assert %SliceLen{type: ~l"usize", src: {0, :keep}} =
             Instruction.parse("slice_len(usize, %0)")
  end

  alias Clr.Air.Instruction.Pointer.PtrSlicePtrPtr

  test "ptr_slice_ptr_ptr" do
    assert %PtrSlicePtrPtr{
             type: {:ptr, :slice, {:ptr, :one, ~l"u8", []}, []},
             src: {13, :clobber}
           } =
             Instruction.parse("ptr_slice_ptr_ptr([]*u8, %13!)")
  end

  alias Clr.Air.Instruction.Pointer.PtrSliceLenPtr

  test "ptr_slice_len_ptr" do
    assert %PtrSliceLenPtr{type: {:ptr, :one, {:lvalue, ["usize"]}, []}, src: {20, :clobber}} =
             Instruction.parse("ptr_slice_len_ptr(*usize, %20!)")
  end

  alias Clr.Air.Instruction.Pointer.ArrayElemVal

  test "array_elem_val" do
    assert %ArrayElemVal{src: {:literal, {:array, 2, _, []}, _}, index_src: {519, :keep}} =
             Instruction.parse(
               "array_elem_val(<[2]debug.Dwarf.Section.Id, .{ .eh_frame, .debug_frame }>, %519)"
             )
  end

  alias Clr.Air.Instruction.Pointer.SliceElemVal

  test "slice_elem_val" do
    assert %SliceElemVal{src: {0, :keep}, index_src: {2, :clobber}} =
             Instruction.parse("slice_elem_val(%0, %2!)")
  end

  alias Clr.Air.Instruction.Pointer.PtrElemVal

  test "ptr_elem_val" do
    assert %PtrElemVal{src: {0, :keep}, index_src: ~l"@Air.Inst.Ref.zero_usize"} =
             Instruction.parse("ptr_elem_val(%0, @Air.Inst.Ref.zero_usize)")
  end

  alias Clr.Air.Instruction.Pointer.PtrElemPtr

  test "ptr_elem_ptr" do
    assert %PtrElemPtr{
             loc: {79, :keep},
             val: {:literal, ~l"usize", 13},
             type: {:ptr, :one, {:optional, ~l"debug.Dwarf.Section"}, []}
           } =
             Instruction.parse("ptr_elem_ptr(*?debug.Dwarf.Section, %79, <usize, 13>)")
  end

  alias Clr.Air.Instruction.Pointer.ArrayToSlice

  test "array_to_slice" do
    assert %ArrayToSlice{type: {:ptr, :slice, ~l"u8", []}, src: {13, :clobber}} =
             Instruction.parse("array_to_slice([]u8, %13!)")
  end

  alias Clr.Air.Instruction.Pointer.FieldParentPtr

  test "field_parent_ptr" do
    assert %FieldParentPtr{index: 0, src: {6, :clobber}} =
             Instruction.parse("field_parent_ptr(%6!, 0)")
  end

  test "error_return_trace" do
    TestAir.assert_unimplemented(:error_return_trace)
  end

  test "set_error_return_trace" do
    TestAir.assert_unimplemented(:set_error_return_trace)
  end

  test "set_err_return_trace_index" do
    TestAir.assert_unimplemented(:set_error_return_trace_index)
  end
end
