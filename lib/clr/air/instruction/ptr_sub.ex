defmodule Clr.Air.Instruction.PtrSub do
  defstruct [:type, :src, :val]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument cs slotref lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ptr_sub <- 'ptr_sub' lparen type cs (slotref / literal) cs argument rparen",
    ptr_sub: [export: true, post_traverse: :ptr_sub]
  )

  def ptr_sub(rest, [val, src, type, "ptr_sub"], context, _, _) do
    {rest, [%__MODULE__{val: val, src: src, type: type}], context}
  end
end
