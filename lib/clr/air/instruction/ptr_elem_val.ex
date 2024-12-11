defmodule Clr.Air.Instruction.PtrElemVal do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :val, :unused]

  def initialize([type, val]), do: %__MODULE__{type: type, val: val}
end
