Mox.defmock(ClrTest.InstructionHandler, for: Clr.Air.Instruction)

defmodule ClrTest.Instruction, do: defstruct([])

defimpl Clr.Air.Instruction, for: ClrTest.Instruction do
  defdelegate analyze(instruction, line, state), to: ClrTest.InstructionHandler
end
