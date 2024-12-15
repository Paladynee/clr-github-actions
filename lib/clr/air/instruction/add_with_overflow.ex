defmodule Clr.Air.Instruction.AddWithOverflow do
  defstruct [:type, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type literal]a)

  Pegasus.parser_from_string(
    "add_with_overflow <- 'add_with_overflow' lparen type cs lineref cs (lineref / name / literal) rparen",
    add_with_overflow: [export: true, post_traverse: :add_with_overflow]
  )

  def add_with_overflow(rest, [rhs, lhs, type, "add_with_overflow"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs, type: type}], context}
  end
end
