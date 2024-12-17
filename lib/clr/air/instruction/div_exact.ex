defmodule Clr.Air.Instruction.DivExact do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "div_exact <- 'div_exact' lparen lineref cs (lineref / lvalue / literal) rparen",
    div_exact: [export: true, post_traverse: :div_exact]
  )

  def div_exact(rest, [rhs, lhs, "div_exact"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
