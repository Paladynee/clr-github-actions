defmodule Clr.Air.Instruction.Max do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen lvalue literal]a)

  Pegasus.parser_from_string(
    "max <- 'max' lparen argument cs argument rparen",
    max: [export: true, post_traverse: :max]
  )

  def max(rest, [rhs, lhs, "max"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
