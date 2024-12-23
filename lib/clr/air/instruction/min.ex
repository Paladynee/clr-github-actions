defmodule Clr.Air.Instruction.Min do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[lineref cs lparen rparen literal]a)

  Pegasus.parser_from_string(
    "min <- 'min' lparen (lineref / literal) cs lineref rparen",
    min: [export: true, post_traverse: :min]
  )

  def min(rest, [rhs, lhs, "min"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
