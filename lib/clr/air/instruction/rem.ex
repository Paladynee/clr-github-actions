defmodule Clr.Air.Instruction.Rem do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "rem <- 'rem' lparen lineref cs (lineref / lvalue / literal) rparen",
    rem: [export: true, post_traverse: :rem]
  )

  def rem(rest, [rhs, lhs, "rem"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
