defmodule Clr.Air.Instruction.Clz do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "clz <- 'clz' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    clz: [export: true, post_traverse: :clz]
  )

  def clz(rest, [rhs, lhs, "clz"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
