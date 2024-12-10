defmodule Clr.Air.Function do
  defstruct [:name, code: %{}]

  def put_lines([function | rest], lines), do: [put_lines(function, lines) | rest]

  def put_lines(function, lines), do: %{function | code: lines}
end
