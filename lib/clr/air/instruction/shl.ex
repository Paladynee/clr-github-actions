defmodule Clr.Air.Instruction.Shl do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "shl <- 'shl' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    shl: [export: true, post_traverse: :shl]
  )

  def shl(rest, [rhs, lhs, "shl"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
