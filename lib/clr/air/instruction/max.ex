defmodule Clr.Air.Instruction.Max do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen lvalue literal]a)

  Pegasus.parser_from_string(
    "max <- 'max' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    max: [export: true, post_traverse: :max]
  )

  def max(rest, [rhs, lhs, "max"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
