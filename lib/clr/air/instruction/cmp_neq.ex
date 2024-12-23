defmodule Clr.Air.Instruction.CmpNeq do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "cmp_neq <- 'cmp_neq' lparen (literal / lineref) cs argument rparen",
    cmp_neq: [export: true, post_traverse: :cmp_neq]
  )

  def cmp_neq(rest, [rhs, lhs, "cmp_neq"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
