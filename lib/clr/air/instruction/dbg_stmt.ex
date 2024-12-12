defmodule Clr.Air.Instruction.DbgStmt do
  @behaviour Clr.Air.Instruction

  defstruct [:range]

  def initialize([range]), do: %__MODULE__{range: range}
end
