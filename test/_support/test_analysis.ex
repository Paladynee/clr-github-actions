defmodule ClrTest.TestAnalysis do
  alias Clr.Air.Function
  alias Clr.Air.Instruction.Dbg
  alias Clr.Block
  import Clr.Air.Lvalue

  def run_analysis(code, args_meta \\ [], preload \\ %{}) do
    %Function{name: ~l"foo.bar"}
    |> Block.new(args_meta)
    |> Map.replace!(:slots, preload)
    |> Block.analyze(code)
  end
end
