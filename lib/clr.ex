defmodule Clr do
  @type type :: term
  @type slot :: nil | non_neg_integer
  @type meta :: %{optional(atom) => term}

  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)
end
