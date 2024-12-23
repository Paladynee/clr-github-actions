defmodule Clr.Air.Instruction.BitOr do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "bit_or <- 'bit_or' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    bit_or: [export: true, post_traverse: :bit_or]
  )

  def bit_or(rest, [rhs, lhs, "bit_or"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
