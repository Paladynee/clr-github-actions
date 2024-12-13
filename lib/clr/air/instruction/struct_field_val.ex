defmodule Clr.Air.Instruction.StructFieldVal do
  defstruct [:src, :index]

  def initialize([src, index]), do: %__MODULE__{src: src, index: index}
end
