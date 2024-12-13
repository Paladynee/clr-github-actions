defmodule Clr.Air.Instruction.IsNonNull do
  defstruct [:line]

  def initialize([line]), do: %__MODULE__{line: line}
end
