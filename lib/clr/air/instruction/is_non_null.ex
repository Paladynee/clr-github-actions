defmodule Clr.Air.Instruction.IsNonNull do
  @behaviour Clr.Air.Instruction

  defstruct [:line]

  def initialize([line]), do: %__MODULE__{line: line}
end
