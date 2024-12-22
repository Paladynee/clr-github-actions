defmodule Clr.Air.Instruction.Min do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)

  Pegasus.parser_from_string(
    "min <- 'min' lparen (lineref / literal) cs (lineref / name) rparen",
    min: [export: true, post_traverse: :min]
  )

  def min(rest, [rhs, lhs, "min"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
