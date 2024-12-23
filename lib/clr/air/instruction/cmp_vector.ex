defmodule Clr.Air.Instruction.CmpVector do
  defstruct [:op, :lhs, :rhs]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    """
    cmp_vector <- 'cmp_vector' lparen op cs (literal / lineref) cs argument rparen
    op <- neq
    neq <- 'neq'
    """,
    cmp_vector: [export: true, post_traverse: :cmp_vector],
    neq: [token: :neq]
  )

  def cmp_vector(rest, [rhs, lhs, op, "cmp_vector"], context, _line, _bytes) do
    {rest, [%__MODULE__{op: op, lhs: lhs, rhs: rhs}], context}
  end
end
