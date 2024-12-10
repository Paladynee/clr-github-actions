defmodule Clr.Air.Instruction.Trap do
  @behaviour Clr.Air.Instruction

  defstruct [:unused]

  def initialize([]), do: %__MODULE__{}
end