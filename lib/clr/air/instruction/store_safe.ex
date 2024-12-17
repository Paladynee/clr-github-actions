defmodule Clr.Air.Instruction.StoreSafe do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "store_safe <- 'store_safe' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    store_safe: [export: true, post_traverse: :store_safe]
  )

  def store_safe(rest, [value, loc, "store_safe"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value, loc: loc}], context}
  end
end
