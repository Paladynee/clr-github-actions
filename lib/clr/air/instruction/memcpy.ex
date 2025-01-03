defmodule Clr.Air.Instruction.Memcpy do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument slotref cs lparen rparen lvalue literal]a)

  Pegasus.parser_from_string(
    "memcpy <- 'memcpy' lparen (lvalue / slotref) cs argument rparen",
    memcpy: [export: true, post_traverse: :memcpy]
  )

  def memcpy(rest, [val, loc, "memcpy"], context, _slot, _bytes) do
    {rest, [%__MODULE__{loc: loc, val: val}], context}
  end
end
