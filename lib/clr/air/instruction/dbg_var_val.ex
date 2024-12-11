defmodule Clr.Air.Instruction.DbgVarVal do
  @behaviour Clr.Air.Instruction

  defstruct [:line, :val, :unused]

  def initialize([line, val]), do: %__MODULE__{line: line, val: val}
end
