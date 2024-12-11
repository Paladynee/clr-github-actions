defmodule Clr.Air.Instruction.PtrAdd do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :line, :val, :unused]

  def initialize([type, line, val]), do: %__MODULE__{type: type, line: line, val: val}
end