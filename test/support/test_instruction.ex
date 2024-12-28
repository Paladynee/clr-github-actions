Mox.defmock(ClrTest.InstructionHandler, for: Clr.Air.Instruction)

defmodule ClrTest.TestInstruction, do: defstruct([])

defimpl Clr.Air.Instruction, for: ClrTest.TestInstruction do
  defdelegate analyze(instruction, state), to: ClrTest.InstructionHandler
end
