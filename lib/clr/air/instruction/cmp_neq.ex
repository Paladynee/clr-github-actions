defmodule Clr.Air.Instruction.CmpNeq do
  defstruct [:line, :value]

  def initialize([line, value]), do: %__MODULE__{line: line, value: value}
end
