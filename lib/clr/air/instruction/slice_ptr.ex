defmodule Clr.Air.Instruction.SlicePtr do
  defstruct [:type, :line]

  def initialize([type, line]), do: %__MODULE__{type: type, line: line}
end
