defmodule Clr.Air.Instruction.Alloc do
  defstruct [:type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "alloc <- 'alloc' lparen type rparen",
    alloc: [export: true, post_traverse: :alloc]
  )

  def alloc(rest, [type, "alloc"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type}], context}
  end
end
