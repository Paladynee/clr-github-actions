defmodule Clr.Air.Instruction.SubSat do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "sub_sat <- 'sub_sat' lparen lineref cs (lineref / lvalue) rparen",
    sub_sat: [export: true, post_traverse: :sub_sat]
  )

  def sub_sat(rest, [rhs, lhs, "sub_sat"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
