defmodule ClrTest.Analysis.UndefinedTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis.Undefined
  alias Clr.Analysis.Undefined.Use
  alias Clr.Air.Function
  alias Clr.Block
  alias Clr.Type

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Map.put(:loc, {47, 47})

    {:ok, config: %Undefined{}, block: block}
  end

  alias Clr.Air.Instruction.Mem.Store

  test "when you store undefined", %{config: config, block: block} do
    block = Block.put_type(block, 47, {:ptr, :one, {:u, 8, %{}}, %{}})

    assert {:cont, new_block} =
             Undefined.analyze(
               %Store{dst: {47, :keep}, src: {:literal, ~l"u8", :undefined}},
               0,
               block,
               config
             )

    assert {:ptr, :one, child, _} = Block.fetch!(new_block, 47)
    assert %{undefined: %{function: ~l"foo.bar", loc: {47, 47}}} = Type.get_meta(child)
  end

  test "writing a value can delete undefined", %{config: config, block: block} do
    block =
      Block.put_type(
        block,
        47,
        {:ptr, :one, {:u, 8, %{undefined: %{function: ~l"foo.bar", loc: {42, 42}}}}, %{}}
      )

    assert {:cont, new_block} =
             Undefined.analyze(
               %Store{dst: {47, :keep}, src: {:literal, ~l"u8", 42}},
               0,
               block,
               config
             )

    assert {:ptr, :one, child, _} = Block.fetch!(new_block, 47)
    assert %{} = Type.get_meta(child)
  end

  alias Clr.Air.Instruction.Mem.Load

  test "when you load undefined", %{config: config, block: block} do
    block =
      Block.put_type(block, 0, {:u, 8, %{undefined: %{function: ~l"foo.bar", loc: {42, 42}}}})

    assert_raise Use, fn ->
      Undefined.analyze(%Load{type: {:u, 8, %{}}, src: {42, :keep}}, 0, block, config)
    end
  end
end
