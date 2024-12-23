defmodule Clr.Air.Instruction.MemsetSafe do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen lvalue literal codeblock]a)

  Pegasus.parser_from_string(
    "memset_safe <- 'memset_safe' lparen (lvalue / lineref) cs (lvalue / lineref / literal) rparen",
    memset_safe: [export: true, post_traverse: :memset_safe]
  )

  def memset_safe(rest, [val, loc, "memset_safe"], context, _line, _bytes) do
    {rest, [%__MODULE__{loc: loc, val: val}], context}
  end
end
