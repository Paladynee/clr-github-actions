defmodule Clr.Air.Instruction.Rem do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:literal])

  Pegasus.parser_from_string(
    "rem <- 'rem' lparen lineref cs (lineref / name / literal) rparen",
    rem: [export: true, post_traverse: :rem]
  )

  def rem(rest, [rhs, lhs, "rem"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
