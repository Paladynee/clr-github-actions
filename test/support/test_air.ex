defmodule ClrTest.TestAir do
  defmacro test_air(name) do\
    lvalue = {:<<>>, [], ["#{name}"]}
    quote do
      name = unquote(name)
      test name do
        import Clr.Air.Lvalue
        assert %Clr.Air.Function{name: sigil_l(unquote(lvalue), [])} =
                 "test/air_examples/#{unquote(name)}.air"
                 |> File.read!()
                 |> Clr.Air.parse()
      end
    end
  end
end
