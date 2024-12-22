defmodule Clr.Air.Instruction.ShlWithOverflow do
  defstruct [:type, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)

  Pegasus.parser_from_string(
    "shl_with_overflow <- 'shl_with_overflow' lparen type cs lineref cs (lineref / lvalue / literal) rparen",
    shl_with_overflow: [export: true, post_traverse: :shl_with_overflow]
  )

  def shl_with_overflow(rest, [rhs, lhs, type, "shl_with_overflow"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs, type: type}], context}
  end
end
