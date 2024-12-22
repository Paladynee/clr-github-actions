defmodule Clr.Air.Instruction.DivTrunc do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "div_trunc <- 'div_trunc' lparen lineref cs (lineref / lvalue / literal) rparen",
    div_trunc: [export: true, post_traverse: :div_trunc]
  )

  def div_trunc(rest, [rhs, lhs, "div_trunc"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
