defmodule Clr.Air.Instruction.IsNonNull do
  @behaviour Clr.Air.Instruction

  defstruct [:line, :unused]

  def initialize([line]), do: %__MODULE__{line: line}
end
