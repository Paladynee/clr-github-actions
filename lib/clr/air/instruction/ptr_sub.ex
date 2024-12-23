defmodule Clr.Air.Instruction.PtrSub do
  defstruct [:type, :line, :val]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[cs lineref lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ptr_sub <- 'ptr_sub' lparen type cs (lineref / literal) cs (lineref / lvalue / literal) rparen",
    ptr_sub: [export: true, post_traverse: :ptr_sub]
  )

  def ptr_sub(rest, [val, line, type, "ptr_sub"], context, _, _) do
    {rest, [%__MODULE__{val: val, line: line, type: type}], context}
  end
end
