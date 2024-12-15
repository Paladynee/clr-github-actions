defmodule Clr.Air.Instruction.BitAnd do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:literal])

  Pegasus.parser_from_string(
    "bit_and <- 'bit_and' lparen lineref cs (lineref / name / literal) rparen",
    bit_and: [export: true, post_traverse: :bit_and]
  )

  def bit_and(rest, [rhs, lhs, "bit_and"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
