defmodule Clr.Air.Instruction.SubWithOverflow do
  defstruct [:type, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "sub_with_overflow <- 'sub_with_overflow' lparen type cs lineref cs (lineref / name) rparen",
    sub_with_overflow: [export: true, post_traverse: :sub_with_overflow]
  )

  def sub_with_overflow(rest, [rhs, lhs, type, "sub_with_overflow"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs, type: type}], context}
  end
end
