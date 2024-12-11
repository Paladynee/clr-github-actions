defmodule Clr.Air.Instruction.Block do
  @behaviour Clr.Air.Instruction

  alias Clr.Air.Instruction

  defstruct [:type, :code, :end, :unused]

  def initialize([type | code]) do
    case List.last(code) do
      {_int, _bool, _instruction} ->
        code = Instruction.to_code(code)
        %__MODULE__{type: type, code: code}
      other ->
        code = code
        |> Enum.slice(0..-2//1)
        |> Instruction.to_code()

        %__MODULE__{type: type, end: other, code: code}
    end
  end
end
