defmodule ClrTest.Analysis.Instruction.MathsTest do
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

  describe "for binary operations" do
    alias Clr.Air.Instruction.Maths.Binary

    test "with peer type resolution, with erasure", %{block: block} do
      block =
        block
        |> Block.put_type(0, {:u, 8, %{foo: :bar}})
        |> Block.put_type(1, {:u, 16, %{bar: :baz}})

      assert {{:u, 16, %{}}, _} =
               Instruction.slot_type(
                 %Binary{lhs: {0, :keep}, rhs: {1, :keep}, op: :add},
                 0,
                 block
               )
    end
  end

  describe "for unary, typed operations" do
    alias Clr.Air.Instruction.Maths.UnaryTyped

    test "type comes from the instruction", %{block: block} do
      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(
                 %UnaryTyped{operand: {0, :keep}, type: ~l"u8", op: :abs},
                 0,
                 block
               )
    end
  end

  describe "for untyped unary operations" do
    alias Clr.Air.Instruction.Maths.Unary

    test "type comes from value, with erasure", %{block: block} do
      block =
        block
        |> Block.put_type(0, {:u, 8, %{foo: :bar}})

      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(%Unary{operand: {0, :keep}, op: :abs}, 0, block)
    end
  end

  describe "for overflow instructions" do
    alias Clr.Air.Instruction.Maths.Overflow

    test "type comes from the instruction", %{block: block} do
      block =
        block
        |> Block.put_type(0, {:u, 8, %{foo: :bar}})
        |> Block.put_type(1, {:u, 16, %{bar: :baz}})

      assert {{:struct, [{:u, 16, %{}}, {:u, 1, %{}}], %{}}, _} =
               Instruction.slot_type(
                 %Overflow{
                   type: {:struct, [~l"u16", ~l"u1"]},
                   lhs: {0, :keep},
                   rhs: {1, :keep},
                   op: :add
                 },
                 0,
                 block
               )
    end
  end
end
