defmodule Clr.Air.Instruction.Slice do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :src, :index]

  def initialize([type, src, index]), do: %__MODULE__{type: type, src: src, index: index}
end
