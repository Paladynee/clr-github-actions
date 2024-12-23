defmodule Clr.Air.Instruction.MulWrap do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "mul_wrap <- 'mul_wrap' lparen argument cs argument rparen",
    mul_wrap: [export: true, post_traverse: :mul_wrap]
  )

  def mul_wrap(rest, [rhs, lhs, "mul_wrap"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
