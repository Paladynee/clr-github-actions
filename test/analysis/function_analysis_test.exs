defmodule ClrTest.Analysis.FunctionAnalysisTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Function
  alias Clr.Analysis
  import Clr.Air.Lvalue

  defp run_analysis(code, args \\ []) do
    Analysis.do_analyze(%Function{name: ~l"foo.bar", code: code}, args)
  end

  describe "generic instructions" do
    test "a keep instruction gets the instruction put into the types slot." do
      Mox.expect(ClrTest.InstructionHandler, :analyze, fn _, _ -> {:foobar, []} end)

      assert %{types: %{0 => :foobar}} = run_analysis(%{{0, :keep} => %ClrTest.Instruction{}})
    end

    test "a clobber instruction does not change the state." do
      empty_map = %{}
      assert %{types: ^empty_map} = run_analysis(%{{0, :clobber} => %ClrTest.Instruction{}})
    end

    test "a subsequent instruction gets the types passed" do
      ClrTest.InstructionHandler
      |> Mox.expect(:analyze, fn _, _ -> {:foobar, []} end)
      |> Mox.expect(:analyze, fn _, %{types: %{0 => :foobar}} -> {:barbaz, []} end)

      assert %{types: %{0 => :foobar, 1 => :barbaz}} =
               run_analysis(%{
                 {0, :keep} => %ClrTest.Instruction{},
                 {1, :keep} => %ClrTest.Instruction{}
               })
    end
  end

  test "temporary, full function test" do
  end
end
