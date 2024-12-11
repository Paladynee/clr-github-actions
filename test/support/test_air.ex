defmodule ClrTest.TestAir do
  defmacro test_air(filename) do
    quote bind_quoted: binding() do 
      test filename do
        assert %Clr.Air.Function{name: "start"} = "test/air_examples/#{unquote(filename)}.air"
        |> File.read!()
        |> Clr.Air.parse()
      end
    end
  end
end