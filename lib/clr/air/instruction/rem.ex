defmodule Clr.Air.Instruction.Rem do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "rem <- 'rem' lparen lineref cs argument rparen",
    rem: [export: true, post_traverse: :rem]
  )

  def rem(rest, [rhs, lhs, "rem"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
