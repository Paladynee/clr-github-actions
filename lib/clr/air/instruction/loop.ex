defmodule Clr.Air.Instruction.Loop do
  @behaviour Clr.Air.Instruction

  alias Clr.Air.Instruction

  defstruct [:type, :code]

  def initialize([type | code]) do
    code = Instruction.to_code(code)

    %__MODULE__{type: type, code: code}
  end
end
