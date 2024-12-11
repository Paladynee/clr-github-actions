defmodule Clr.Air.Instruction.Assembly do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :in1, :in2, :code, :unused]

  def initialize([type, "volatile", in1, in2, code]),
    do: %__MODULE__{
      type: type,
      in1: in1,
      in2: in2,
      code: code
    }
end
