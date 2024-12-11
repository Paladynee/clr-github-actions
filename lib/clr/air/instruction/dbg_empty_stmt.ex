defmodule Clr.Air.Instruction.DbgEmptyStmt do
  @behaviour Clr.Air.Instruction

  defstruct [:unused]

  def initialize([]), do: %__MODULE__{}
end
