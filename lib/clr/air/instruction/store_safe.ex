defmodule Clr.Air.Instruction.StoreSafe do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type literal lvalue lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "store_safe <- 'store_safe' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    store_safe: [export: true, post_traverse: :store_safe]
  )

  def store_safe(rest, [value, loc, "store_safe"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value, loc: loc}], context}
  end
end
