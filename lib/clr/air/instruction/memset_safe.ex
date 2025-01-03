defmodule Clr.Air.Instruction.MemsetSafe do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument slotref cs lparen rparen lvalue literal codeblock]a)

  Pegasus.parser_from_string(
    "memset_safe <- 'memset_safe' lparen (lvalue / slotref) cs argument rparen",
    memset_safe: [export: true, post_traverse: :memset_safe]
  )

  def memset_safe(rest, [val, loc, "memset_safe"], context, _slot, _bytes) do
    {rest, [%__MODULE__{loc: loc, val: val}], context}
  end
end
