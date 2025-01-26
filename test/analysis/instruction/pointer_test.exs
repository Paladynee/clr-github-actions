defmodule ClrTest.Analysis.Instruction.PointerTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Instruction
  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Map.put(:loc, {47, 47})

    {:ok, block: block, config: %Instruction{}}
  end

  describe "op" do
    alias Clr.Air.Instruction.Pointer.Op

    test "correctly makes the type", %{block: block} do
      assert {{:ptr, :many, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %Op{type: {:ptr, :many, ~l"u8", []}, src: ~l"foo", val: ~l"bar"},
                 0,
                 block
               )
    end
  end

  @tag :skip
  test "struct_field_ptr"

  @tag :skip
  test "struct_field_ptr_index"

  describe "slice" do
    alias Clr.Air.Instruction.Pointer.Slice

    test "uses the type pointer", %{block: block} do
      assert {{:ptr, :slice, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %Slice{type: {:ptr, :slice, ~l"u8", []}, src: ~l"foo", len: ~l"bar"},
                 0,
                 block
               )
    end

    @tag :skip
    test "make slice respect when src is a qualified pointer"
  end

  alias Clr.Air.Instruction.Pointer.SliceLen

  test "slice_len returns usize", %{block: block} do
    assert {{:usize, %{}}, _} =
             Instruction.slot_type(%SliceLen{type: ~l"usize", src: ~l"foo"}, 0, block)
  end

  describe "slice_ptr" do
    alias Clr.Air.Instruction.Pointer.SlicePtr

    test "uses the type pointer", %{block: block} do
      assert {{:ptr, :many, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %SlicePtr{type: {:ptr, :many, ~l"u8", []}, src: ~l"foo"},
                 0,
                 block
               )
    end

    @tag :skip
    test "make slice_ptr respect when src is a qualified pointer"
  end

  alias Clr.Air.Instruction.Pointer.PtrSliceLenPtr

  test "ptr_slice_len_ptr", %{block: block} do
    assert {{:ptr, :one, {:usize, %{}}, %{}}, _} =
             Instruction.slot_type(
               %PtrSliceLenPtr{type: {:ptr, :one, ~l"usize", []}, src: ~l"foo"},
               0,
               block
             )
  end

  alias Clr.Air.Instruction.Pointer.PtrSlicePtrPtr

  describe "ptr_slice_ptr_ptr" do
    test "uses the type pointer", %{block: block} do
      assert {{:ptr, :one, {:ptr, :many, {:u, 8, %{}}, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %PtrSlicePtrPtr{type: {:ptr, :one, {:ptr, :many, ~l"u8", []}, []}, src: ~l"foo"},
                 0,
                 block
               )
    end

    @tag :skip
    test "make ptr_slice_ptr_ptr respect when src is a qualified pointer"
  end

  alias Clr.Air.Instruction.Pointer.ArrayElemVal

  test "array_elem_val returns the internal type", %{block: block} do
    block = Block.put_type(block, 0, {:array, {:u, 8, %{}}, %{}})

    assert {{:u, 8, %{}}, _} =
             Instruction.slot_type(
               %ArrayElemVal{src: {0, :keep}, index_src: ~l"foo"},
               0,
               block
             )
  end

  alias Clr.Air.Instruction.Pointer.SliceElemVal

  test "slice_elem_val returns the internal type", %{block: block} do
    block = Block.put_type(block, 0, {:ptr, :slice, {:u, 8, %{}}, %{}})

    assert {{:u, 8, %{}}, _} =
             Instruction.slot_type(
               %SliceElemVal{src: {0, :keep}, index_src: ~l"foo"},
               0,
               block
             )
  end

  alias Clr.Air.Instruction.Pointer.SliceElemPtr

  describe "slice_elem_ptr" do
    @tag :skip
    test "returns the internal type"
  end

  @tag :skip
  test "ptr_elem_val"

  @tag :skip
  test "ptr_elem_ptr"

  @tag :skip
  test "array_to_slice"

  @tag :skip
  test "field_parent_ptr"
end
