defmodule ClrTest.Analysis.Instruction.MemTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Instruction
  alias Clr.Air.Function
  alias Clr.Block
  alias Clr.Type

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Map.put(:loc, {47, 47})

    {:ok, block: block, config: %Instruction{}}
  end

  describe "alloc" do
    alias Clr.Air.Instruction.Mem.Alloc

    test "correctly makes the type", %{block: block} do
      assert {{:ptr, :one, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(%Alloc{type: {:ptr, :one, ~l"u8", []}}, 0, block)
    end
  end

  describe "load" do
    alias Clr.Air.Instruction.Mem.Load

    test "pulls from the type field when it's a literal", %{block: block} do
      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(
                 %Load{type: ~l"u8", src: {:literal, {:ptr, :one, ~l"u8", []}, ~l"bar.baz"}},
                 0,
                 block
               )
    end

    test "pulls from the type field when it's an lvalue", %{block: block} do
      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(
                 %Load{type: ~l"u8", src: ~l"@Air.Inst.Ref.one_u8"},
                 0,
                 block
               )
    end

    test "pulls from the slotref when it's a slotref", %{block: block} do
      block = Block.put_type(block, 0, {:ptr, :one, {:u, 8, %{foo: :bar}}, %{}})

      assert {{:u, 8, %{foo: :bar}}, _} =
               Instruction.slot_type(%Load{type: ~l"u8", src: {0, :keep}}, 0, block)
    end
  end

  describe "store" do
    alias Clr.Air.Instruction.Mem.Store

    test "sets slot_type to void", %{block: block} do
      block = Block.put_type(block, 0, {:u, 8, %{}})

      assert {:void, _} =
               Instruction.slot_type(
                 %Store{src: ~l"@Air.Inst.Ref.one_u8", dst: {0, :keep}, safe: false},
                 0,
                 block
               )
    end

    test "when analyzed, moves in all other features from the slot", %{
      config: config,
      block: block
    } do
      block =
        block
        |> Block.put_type(47, {:ptr, :one, {:u, 8, %{}}, %{}})
        |> Block.put_type(48, {:u, 8, %{foo: :bar}})

      assert {:cont, new_block} =
               Instruction.analyze(
                 %Store{dst: {47, :keep}, src: {48, :keep}},
                 0,
                 block,
                 config
               )

      assert {:ptr, :one, child, _} = Block.fetch!(new_block, 47)
      assert %{foo: :bar} = Type.get_meta(child)
    end
  end

  @tag :skip
  test "struct_field_val"

  @tag :skip
  test "set_union_tag"

  @tag :skip
  test "memset"

  @tag :skip
  test "memcpy"

  @tag :skip
  test "aggregate_init"

  @tag :skip
  test "union_init"

  @tag :skip
  test "prefetch"
end
