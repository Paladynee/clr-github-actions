defmodule Clr.Air.Instruction.Br do
  # represents a `break` statement

  @behaviour Clr.Air.Instruction

  defstruct [:goto, :value]

  def initialize([goto, value]), do: %__MODULE__{goto: goto, value: value}
end
