defmodule Clr.Air.Instruction.Memcpy do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "memcpy <- 'memcpy' lparen (lvalue / lineref) cs (lvalue / lineref / literal) rparen",
    memcpy: [export: true, post_traverse: :memcpy]
  )

  def memcpy(rest, [val, loc, "memcpy"], context, _line, _bytes) do
    {rest, [%__MODULE__{loc: loc, val: val}], context}
  end
end
