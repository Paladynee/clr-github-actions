defmodule Clr.Air.Instruction.Mul do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "mul <- 'mul' lparen argument cs argument rparen",
    mul: [export: true, post_traverse: :mul]
  )

  def mul(rest, [rhs, lhs, "mul"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
