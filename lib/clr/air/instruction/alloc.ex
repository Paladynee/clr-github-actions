defmodule Clr.Air.Instruction.Alloc do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :unused]

  def initialize([type]), do: %__MODULE__{type: type}
end