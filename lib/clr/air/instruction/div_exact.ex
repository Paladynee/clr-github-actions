defmodule Clr.Air.Instruction.DivExact do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:literal])

  Pegasus.parser_from_string(
    "div_exact <- 'div_exact' lparen lineref cs (lineref / name / literal) rparen",
    div_exact: [export: true, post_traverse: :div_exact]
  )

  def div_exact(rest, [rhs, lhs, "div_exact"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
