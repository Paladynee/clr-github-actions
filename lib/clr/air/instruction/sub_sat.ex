defmodule Clr.Air.Instruction.SubSat do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "sub_sat <- 'sub_sat' lparen lineref cs argument rparen",
    sub_sat: [export: true, post_traverse: :sub_sat]
  )

  def sub_sat(rest, [rhs, lhs, "sub_sat"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
