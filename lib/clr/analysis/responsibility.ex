defmodule Clr.Analysis.Responsibility do
  def maybe_set_manages(analysis, line) do
    if passed_parameter?(analysis, line) do
      %{analysis | args: List.update_at(analysis.args, line, &set_manages/1)}
    else
      analysis
    end
  end

  defp passed_parameter?(analysis, line), do: line < length(analysis.args)

  defp set_manages({:ptr, count, type, opts}) do
    {:ptr, count, type, Keyword.put(opts, :responsibility, :transferred)}
  end
end
