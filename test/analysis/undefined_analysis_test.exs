defmodule ClrTest.Function.UndefinedAnalysisTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis.Undefined
  alias Clr.Air.Instruction.Mem.Store
  alias Clr.Air.Function
  alias Clr.Block

  import ClrTest.TestAnalysis
  import Clr.Air.Lvalue

  setup do
    block = Block.new(%Function{name: ~l"foo.bar"}, [])
    {:ok, config: %Undefined{}, block: block}
  end

  test "when you store undefined", %{config: config, block: block} do
    assert {:u, 8, %{undefined: true}} = block
    |> Block.put_type(19, {:u, 8, %{}})
    |> then(&Undefined.analyze(%Store{loc: {19, :keep}, src: ~l"undefined"}, 0, &1, config))
    |> then(fn {:halt, {:void, new_block}} -> new_block end)
    |> Block.get_meta(19)
  end
end