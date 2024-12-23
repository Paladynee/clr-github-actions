defmodule Clr.Air.Instruction.ShlWithOverflow do
  defstruct [:type, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument type lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "shl_with_overflow <- 'shl_with_overflow' lparen type cs lineref cs argument rparen",
    shl_with_overflow: [export: true, post_traverse: :shl_with_overflow]
  )

  def shl_with_overflow(rest, [rhs, lhs, type, "shl_with_overflow"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs, type: type}], context}
  end
end
