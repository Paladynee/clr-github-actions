defmodule Clr.Air.Instruction.Shr do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument cs lparen rparen]a)

  Pegasus.parser_from_string(
    "shr <- 'shr' lparen argument cs argument rparen",
    shr: [export: true, post_traverse: :shr]
  )

  def shr(rest, [rhs, lhs, "shr"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
