defmodule Clr.Air.Instruction.CmpLte do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "cmp_lte <- 'cmp_lte' lparen (lineref / lvalue / literal) cs (lineref / literal / lvalue) rparen",
    cmp_lte: [export: true, post_traverse: :cmp_lte]
  )

  def cmp_lte(rest, [rhs, lhs, "cmp_lte"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
