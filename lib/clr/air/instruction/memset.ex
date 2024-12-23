defmodule Clr.Air.Instruction.Memset do
  defstruct [:loc, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen lvalue codeblock]a)

  Pegasus.parser_from_string(
    "memset <- 'memset' lparen (lvalue / lineref) cs lvalue rparen",
    memset: [export: true, post_traverse: :memset]
  )

  def memset(rest, [val, loc, "memset"], context, _line, _bytes) do
    {rest, [%__MODULE__{loc: loc, val: val}], context}
  end
end
