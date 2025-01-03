defmodule Clr.Air.Instruction.PtrAdd do
  defstruct [:type, :src, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument cs slotref lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ptr_add <- 'ptr_add' lparen type cs (slotref / literal) cs argument rparen",
    ptr_add: [export: true, post_traverse: :ptr_add]
  )

  def ptr_add(rest, [val, src, type, "ptr_add"], context, _, _) do
    {rest, [%__MODULE__{val: val, src: src, type: type}], context}
  end
end
