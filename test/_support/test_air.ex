defmodule ClrTest.TestAir do
  defmacro test_air(name) do
    lvalue = {:<<>>, [], ["#{name}"]}

    quote do
      name = unquote(name)

      test name do
        import Clr.Air.Lvalue

        assert %Clr.Air.Function{name: sigil_l(unquote(lvalue), [])} =
                 "test/air_examples/#{unquote(name)}.air"
                 |> File.read!()
                 |> Clr.Air.Function.parse()
      end
    end
  end

  def assert_unimplemented(instruction) do
    import ExUnit.Assertions

    assert_raise RuntimeError, "Instruction #{instruction} unimplemented", fn ->
      Clr.Air.Instruction.parse("#{instruction}()")
    end
  end
end
