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
end
