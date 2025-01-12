defmodule Clr.Air.Instruction.Alloc do
  defstruct [:type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref lparen rparen]a)

  Pegasus.parser_from_string(
    "alloc <- 'alloc' lparen type rparen",
    alloc: [export: true, post_traverse: :alloc]
  )

  def alloc(rest, [type, "alloc"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type}], context}
  end

  use Clr.Air.Instruction

  alias Clr.Block

  def analyze(%{type: {:ptr, _, _, _} = type}, slot, analysis) do
    Block.put_type(analysis, slot, type, stack: analysis.function)
  end
end
