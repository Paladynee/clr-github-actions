defmodule Clr.Air.Instruction.Trunc do
  defstruct [:type, :line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "trunc <- 'trunc' lparen type cs lineref rparen",
    trunc: [export: true, post_traverse: :trunc]
  )

  def trunc(rest, [line, type, "trunc"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, line: line}], context}
  end
end
