defmodule Clr.Air.Instruction.Block do
  @behaviour Clr.Air.Instruction

  defstruct [:type, :code]

  def initialize([type | code]) do
    code =
      Enum.reduce(code, %{}, fn
        {:clobber, number}, acc ->
          Map.update(acc, :clobbers, [number], &[number | &1])

        {k, v}, acc ->
          Map.put(acc, k, v)
      end)

    %__MODULE__{type: type, code: code}
  end
end
