defmodule Clr.Air.Instruction.CmpEq do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "cmp_eq <- 'cmp_eq' lparen lineref cs literal rparen",
    cmp_eq: [export: true, post_traverse: :cmp_eq]
  )

  def cmp_eq(rest, [rhs, lhs, "cmp_eq"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
