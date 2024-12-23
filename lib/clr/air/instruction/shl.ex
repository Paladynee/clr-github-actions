defmodule Clr.Air.Instruction.Shl do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "shl <- 'shl' lparen argument cs argument rparen",
    shl: [export: true, post_traverse: :shl]
  )

  def shl(rest, [rhs, lhs, "shl"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
