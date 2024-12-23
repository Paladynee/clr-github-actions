defmodule Clr.Air.Instruction.Sub do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "sub <- 'sub' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    sub: [export: true, post_traverse: :sub]
  )

  def sub(rest, [rhs, lhs, "sub"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
