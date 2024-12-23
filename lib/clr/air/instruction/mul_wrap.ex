defmodule Clr.Air.Instruction.MulWrap do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "mul_wrap <- 'mul_wrap' lparen (lineref / lvalue /literal) cs (lineref / lvalue / literal) rparen",
    mul_wrap: [export: true, post_traverse: :mul_wrap]
  )

  def mul_wrap(rest, [rhs, lhs, "mul_wrap"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
