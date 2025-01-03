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

  alias Clr.Analysis

  def analyze(%{type: {:ptr, ptrtype, child, opts}}, slot, analysis) do
    Analysis.put_type(
      analysis,
      slot,
      {:ptr, ptrtype, child, Keyword.put(opts, :stack, analysis.name)}
    )
  end
end
