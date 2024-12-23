defmodule Clr.Air.Instruction.Store do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen lvalue literal type]a)

  Pegasus.parser_from_string(
    "store <- 'store' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    store: [export: true, post_traverse: :store]
  )

  def store(rest, [value, loc, "store"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value, loc: loc}], context}
  end
end
