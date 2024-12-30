defmodule Clr do
  def debug_prefix, do: Application.get_env(:clr, :debug_prefix) 
end
