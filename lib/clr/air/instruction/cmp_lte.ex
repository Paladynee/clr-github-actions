defmodule Clr.Air.Instruction.CmpLte do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[name lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:int_literal])

  Pegasus.parser_from_string(
    "cmp_lte <- 'cmp_lte' lparen (lineref / name) cs (lineref / int_literal) rparen",
    cmp_lte: [export: true, post_traverse: :cmp_lte]
  )

  def cmp_lte(rest, [rhs, lhs, "cmp_lte"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
