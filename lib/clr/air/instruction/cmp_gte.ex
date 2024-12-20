defmodule Clr.Air.Instruction.CmpGte do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "cmp_gte <- 'cmp_gte' lparen (lineref / lvalue / literal) cs (lineref / literal) rparen",
    cmp_gte: [export: true, post_traverse: :cmp_gte]
  )

  def cmp_gte(rest, [rhs, lhs, "cmp_gte"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
