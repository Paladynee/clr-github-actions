defmodule Clr.Air.Instruction.DbgStmt do
  @behaviour Clr.Air.Instruction

  defstruct [:range, :unused]

  def initialize([range]), do: %__MODULE__{range: range}
end
