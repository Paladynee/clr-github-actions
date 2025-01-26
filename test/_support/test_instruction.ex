Mox.defmock(ClrTest.InstructionHandler, for: Clr.Air.Instruction)

defmodule ClrTest.Instruction, do: defstruct([])

defimpl Clr.Air.Instruction, for: ClrTest.Instruction do
  defdelegate analyze(instruction, slot, block, config), to: ClrTest.InstructionHandler
  defdelegate slot_type(instruction, slot, block), to: ClrTest.InstructionHandler
end
