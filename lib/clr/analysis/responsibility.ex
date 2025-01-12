defmodule Clr.Function.Responsibility do
  def maybe_set_manages(analysis, slot) do
    if passed_parameter?(analysis, slot) do
      %{analysis | args: List.update_at(analysis.args, slot, &set_manages/1)}
    else
      analysis
    end
  end

  defp passed_parameter?(analysis, slot), do: slot < length(analysis.args)

  defp set_manages({:ptr, count, type, opts}) do
    {:ptr, count, type, Keyword.put(opts, :responsibility, :transferred)}
  end
end
