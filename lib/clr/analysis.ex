defmodule Clr.Analysis do
  def analyze(function) do
    Clr.Server.get_function(function)
  end
end