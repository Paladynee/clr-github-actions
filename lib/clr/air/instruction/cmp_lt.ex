defmodule Clr.Air.Instruction.CmpLt do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "cmp_lt <- 'cmp_lt' lparen argument cs argument rparen",
    cmp_lt: [export: true, post_traverse: :cmp_lt]
  )

  def cmp_lt(rest, [rhs, lhs, "cmp_lt"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
