defmodule Clr.Air.Instruction.PtrElemVal do
  defstruct [:src, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "ptr_elem_val <- 'ptr_elem_val' lparen slotref cs argument rparen",
    ptr_elem_val: [export: true, post_traverse: :ptr_elem_val]
  )

  defp ptr_elem_val(rest, [val, src, "ptr_elem_val"], context, _slot, _byte) do
    {rest, [%__MODULE__{src: src, val: val}], context}
  end
end
