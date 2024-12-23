defmodule Clr.Air.Instruction.Mod do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "mod <- 'mod' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    mod: [export: true, post_traverse: :mod]
  )

  def mod(rest, [rhs, lhs, "mod"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
