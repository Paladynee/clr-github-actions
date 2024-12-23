defmodule Clr.Air.Instruction.Mul do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "mul <- 'mul' lparen (lineref / lvalue /literal) cs (lineref / lvalue / literal) rparen",
    mul: [export: true, post_traverse: :mul]
  )

  def mul(rest, [rhs, lhs, "mul"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
