defmodule Clr.Air.Instruction.Xor do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "xor <- 'xor' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    xor: [export: true, post_traverse: :xor]
  )

  def xor(rest, [rhs, lhs, "xor"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
