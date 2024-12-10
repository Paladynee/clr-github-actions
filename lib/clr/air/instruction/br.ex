defmodule Clr.Air.Instruction.Br do
  # represents a `break` statement

  @behaviour Clr.Air.Instruction

  defstruct [:line, :value, :unused]

  def initialize([line, value]), do: %__MODULE__{line: line, value: value}
end