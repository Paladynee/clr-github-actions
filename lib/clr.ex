defmodule Clr do
  @type type :: term

  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)
end
