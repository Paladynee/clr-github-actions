defmodule Clr.Air.Instruction.Bitcast do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :line, :unused]

  def initialize([type, line]), do: %__MODULE__{type: type, line: line}
end