defmodule Clr.Air.Instruction.Abs do
  defstruct [:src, :type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "abs <- 'abs' lparen type cs (lineref / lvalue / literal) rparen",
    abs: [export: true, post_traverse: :abs]
  )

  def abs(rest, [src, type, "abs"], context, _line, _bytes) do
    {rest, [%__MODULE__{src: src, type: type}], context}
  end
end
