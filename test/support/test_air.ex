defmodule ClrTest.TestAir do
  defmacro test_air(name) do
    quote bind_quoted: binding() do
      test name do
        assert %Clr.Air.Function{name: unquote(name)} =
                 "test/air_examples/#{unquote(name)}.air"
                 |> File.read!()
                 |> Clr.Air.parse()
      end
    end
  end
end
