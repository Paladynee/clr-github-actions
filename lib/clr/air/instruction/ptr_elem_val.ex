defmodule Clr.Air.Instruction.PtrElemVal do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :val]

  def initialize([type, val]), do: %__MODULE__{type: type, val: val}
end
