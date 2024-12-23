defmodule Clr.Air.Instruction.BitOr do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "bit_or <- 'bit_or' lparen argument cs argument rparen",
    bit_or: [export: true, post_traverse: :bit_or]
  )

  def bit_or(rest, [rhs, lhs, "bit_or"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
