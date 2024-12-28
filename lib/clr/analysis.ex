defmodule Clr.Analysis do
  defstruct [:name, :arguments, types: %{}]

  def analyze(function_name, arguments) do
    # walk the function code and analyze it
    function_name
    |> Clr.Air.Server.get()
    |> do_analyze(arguments)
  end

  def do_analyze(function, arguments) do
    Enum.reduce(
      function.code,
      %__MODULE__{name: function.name, arguments: arguments},
      &analysis/2
    )
  end

  # values that are clobbered can be safely ignored.
  defp analysis({{_, :clobber}, _}, state), do: state

  defp analysis({{line, :keep}, function}, state) do
    {result, _param_type_changes} = Clr.Air.Instruction.analyze(function, state)
    %{state | types: Map.put(state.types, line, result)}
  end
end
