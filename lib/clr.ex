defmodule Clr do
  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)

  def location_string(function, {row, _col}) do
    "function `#{function}`, row #{row}"
  end
end
