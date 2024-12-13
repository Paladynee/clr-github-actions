defmodule Clr.Air.Instruction.Repeat do
  defstruct [:goto]

  def initialize([goto]) do
    %__MODULE__{goto: goto}
  end
end
