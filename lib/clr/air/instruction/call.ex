defmodule Clr.Air.Instruction.Call do
  defstruct [:type, :function, :args]

  def initialize([{type, {:function, function}} | args]) do
    %__MODULE__{type: type, function: function, args: args}
  end
end
