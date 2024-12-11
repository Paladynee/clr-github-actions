defmodule Clr.Air.Instruction.DbgInlineBlock do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :what, :unused]

  def initialize([blocktype, what | code]) do
    %__MODULE__{type: blocktype, what: what}
  end
end
