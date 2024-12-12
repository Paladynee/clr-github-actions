defmodule Clr.Air.Instruction.Repeat do
  @behaviour Clr.Air.Instruction

  defstruct [:goto]

  def initialize([goto]) do
    %__MODULE__{goto: goto}
  end
end
