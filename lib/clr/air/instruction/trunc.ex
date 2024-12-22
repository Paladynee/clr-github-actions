defmodule Clr.Air.Instruction.Trunc do
  defstruct [:type, :line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "trunc <- 'trunc' lparen type cs (lineref / name) rparen",
    trunc: [export: true, post_traverse: :trunc]
  )

  def trunc(rest, [line, type, "trunc"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, line: line}], context}
  end
end
