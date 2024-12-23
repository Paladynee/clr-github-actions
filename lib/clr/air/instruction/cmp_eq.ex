defmodule Clr.Air.Instruction.CmpEq do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "cmp_eq <- 'cmp_eq' lparen argument cs argument rparen",
    cmp_eq: [export: true, post_traverse: :cmp_eq]
  )

  def cmp_eq(rest, [rhs, lhs, "cmp_eq"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
