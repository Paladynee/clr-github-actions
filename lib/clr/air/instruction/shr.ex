defmodule Clr.Air.Instruction.Shr do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "shr <- 'shr' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    shr: [export: true, post_traverse: :shr]
  )

  def shr(rest, [rhs, lhs, "shr"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
