defmodule ClrTest.Analysis.Instruction.TestsTest do
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

  alias Clr.Air.Instruction.Tests.Compare

  test "compare makes bool always", %{block: block} do
    assert {{:bool, %{}}, _} = Instruction.slot_type(%Compare{op: :eq}, 0, block)
  end

  alias Clr.Air.Instruction.Tests.Is

  test "is makes bool always", %{block: block} do
    assert {{:bool, %{}}, _} = Instruction.slot_type(%Is{}, 0, block)
  end
end
