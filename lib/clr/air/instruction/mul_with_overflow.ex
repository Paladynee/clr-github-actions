defmodule Clr.Air.Instruction.MulWithOverflow do
  defstruct [:type, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)

  Pegasus.parser_from_string(
    "mul_with_overflow <- 'mul_with_overflow' lparen type cs (lineref / literal) cs (lineref / lvalue / literal) rparen",
    mul_with_overflow: [export: true, post_traverse: :mul_with_overflow]
  )

  def mul_with_overflow(rest, [rhs, lhs, type, "mul_with_overflow"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs, type: type}], context}
  end
end
