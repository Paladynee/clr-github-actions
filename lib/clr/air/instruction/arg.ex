defmodule Clr.Air.Instruction.Arg do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :name, :unused]

  def initialize([type, name]), do: %__MODULE__{type: type, name: name}
end
