defmodule ClrTest.Function.UndefinedAnalysisTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis.Undefined
  alias Clr.Air.Function
  alias Clr.Block

  import ClrTest.TestAnalysis
  import Clr.Air.Lvalue

  setup do
    block = Block.new(%Function{name: ~l"foo.bar"}, [])
    {:ok, config: %Undefined{}, block: block}
  end

  alias Clr.Air.Instruction.Mem.Store

  test "when you store undefined", %{config: config, block: block} do
    assert {:u, 8, %{undefined: true}} =
             block
             |> Block.put_type(47, {:u, 8, %{}})
             |> then(
               &Undefined.analyze(%Store{loc: {47, :keep}, src: ~l"undefined"}, 0, &1, config)
             )
             |> then(fn {:halt, {:void, new_block}} -> new_block end)
             |> Block.get_meta(47)
  end

  alias Clr.Air.Instruction.Mem.Load

  test "when you load undefined", %{config: config, block: block} do
    assert_raise FooBar, fn ->
      block
      |> Block.put_type(42, {:u, 8, %{undefined: true}})
      |> then(&Undefined.analyze(%Load{type: {:u, 8, %{}}, src: {42, :keep}}, 0, &1, config))
    end
  end
end
