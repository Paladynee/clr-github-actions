defmodule Clr.Air.Instruction.Call do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :function, :args]

  def initialize([{type, {:function, function}} | args]) do
    %__MODULE__{type: type, function: function, args: args}
  end
end
