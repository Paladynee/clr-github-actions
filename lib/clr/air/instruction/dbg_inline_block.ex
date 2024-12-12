defmodule Clr.Air.Instruction.DbgInlineBlock do
  @behaviour Clr.Air.Instruction

  alias Clr.Air.Instruction

  defstruct [:type, :what, :code]

  def initialize([blocktype, what | code]) do
    %__MODULE__{type: blocktype, what: what, code: Instruction.to_code(code)}
  end
end
