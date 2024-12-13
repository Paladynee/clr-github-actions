defmodule Clr.Air.Instruction.DbgEmptyStmt do
  defstruct [:unused]

  def initialize([]), do: %__MODULE__{}
end
