defmodule Clr do
  @type type :: term
  @type slot :: non_neg_integer

  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)
end
