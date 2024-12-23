defmodule Clr.Air.Instruction.CmpVector do
  defstruct [:op, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    """
    cmp_vector <- 'cmp_vector' lparen op cs (literal / lineref) cs (literal / lvalue / lineref) rparen
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
