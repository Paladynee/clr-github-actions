defmodule Clr.Air.Instruction.AddSat do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "add_sat <- 'add_sat' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    add_sat: [export: true, post_traverse: :add_sat]
  )

  def add_sat(rest, [rhs, lhs, "add_sat"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
