Mox.defmock(ClrTest.InstructionHandler, for: Clr.Air.Instruction)

defmodule ClrTest.Instruction, do: defstruct([])

defimpl Clr.Air.Instruction, for: ClrTest.Instruction do
  defdelegate analyze(instruction, state), to: ClrTest.InstructionHandler
end
