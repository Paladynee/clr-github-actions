defmodule Clr.Air.Instruction.DivExact do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "div_exact <- 'div_exact' lparen lineref cs argument rparen",
    div_exact: [export: true, post_traverse: :div_exact]
  )

  def div_exact(rest, [rhs, lhs, "div_exact"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
