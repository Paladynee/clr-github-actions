defmodule ClrTest.Analysis.Instruction.ControlFlowTest do
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

  describe "block" do
    # not done until we have an iterative way of doing the block.
    @tag :skip
    test "returns the expected type"
  end

  describe "loop" do
    # not done until we have an iterative way of testing the loop result.
    @tag :skip
    test "returns the expected type"
  end

  describe "repeat" do
    # not done until we have an iterative way of testing loops.
    @tag :skip
    test "returns the expected type"
  end

  describe "br" do
    # not done until we have an iterative way of testing the loops.
    @tag :skip
    test "returns the expected type"
  end

  describe "cond_br" do
    # not done until we have an iterative way of testing if statements.
    @tag :skip
    test "returns the expected type"
  end

  describe "switch_br" do
    # not done until we have an iterative way of testing switch statements.
    @tag :skip
    test "returns the expected type"
  end

  describe "switch_dispatch" do
    # not done until we have an iterative way of testing switch statements.
    @tag :skip
    test "returns the expected type"
  end

  describe "try" do
    alias Clr.Air.Instruction.ControlFlow.Try

    test "returns the unwrapped type", %{block: block} do
      block =
        Block.put_type(block, 0, {:errorunion, [~l"error"], {:u, 8, %{foo: :bar}}, %{}})

      assert {{:u, 8, %{foo: :bar}}, _block} =
               Instruction.slot_type(%Try{src: {0, :keep}}, 0, block)
    end
  end

  describe "try_ptr" do
    alias Clr.Air.Instruction.ControlFlow.TryPtr

    test "returns the unwrapped type", %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:ptr, :one, {:errorunion, [~l"error"], {:u, 8, %{}}, %{}}, %{foo: :bar}}
        )

      assert {{:ptr, :one, {:u, 8, %{}}, %{foo: :bar}}, _block} =
               Instruction.slot_type(%TryPtr{src: {0, :keep}}, 0, block)
    end
  end

  describe "unreach" do
    alias Clr.Air.Instruction.ControlFlow.Unreach

    test "returns noreturn as the type", %{block: block} do
      assert {:noreturn, _} = Instruction.slot_type(%Unreach{}, 0, block)
    end
  end
end
