defmodule Clr.Air.Instruction.StructFieldVal do
  @behaviour Clr.Air.Instruction

  defstruct [:src, :index, :unused]

  def initialize([src, index]), do: %__MODULE__{src: src, index: index}
end