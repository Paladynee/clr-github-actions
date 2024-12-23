defmodule Clr.Air.Instruction.CmpLt do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "cmp_lt <- 'cmp_lt' lparen (lineref / literal / lvalue) cs (lineref / literal / lvalue) rparen",
    cmp_lt: [export: true, post_traverse: :cmp_lt]
  )

  def cmp_lt(rest, [rhs, lhs, "cmp_lt"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
