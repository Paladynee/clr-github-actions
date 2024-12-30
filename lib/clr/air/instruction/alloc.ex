defmodule Clr.Air.Instruction.Alloc do
  defstruct [:type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref lparen rparen]a)

  Pegasus.parser_from_string(
    "alloc <- 'alloc' lparen type rparen",
    alloc: [export: true, post_traverse: :alloc]
  )

  def alloc(rest, [type, "alloc"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type}], context}
  end

  use Clr.Air.Instruction

  alias Clr.Analysis

  def analyze(%{type: {:ptr, ptrtype, child, opts}}, line, analysis) do
    Analysis.put_type(
      analysis,
      line,
      {:ptr, ptrtype, child, Keyword.put(opts, :stack, analysis.name)}
    )
  end
end
