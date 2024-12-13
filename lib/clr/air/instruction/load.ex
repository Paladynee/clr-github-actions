defmodule Clr.Air.Instruction.Load do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type literal]a)

  Pegasus.parser_from_string(
    "load <- 'load' lparen type cs lineref rparen",
    load: [export: true, post_traverse: :load]
  )

  def load(rest, [loc, type, "load"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end
end
