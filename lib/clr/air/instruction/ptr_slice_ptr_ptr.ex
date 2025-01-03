defmodule Clr.Air.Instruction.PtrSlicePtrPtr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "ptr_slice_ptr_ptr <- 'ptr_slice_ptr_ptr' lparen type cs argument rparen",
    ptr_slice_ptr_ptr: [export: true, post_traverse: :ptr_slice_ptr_ptr]
  )

  defp ptr_slice_ptr_ptr(rest, [src, type, "ptr_slice_ptr_ptr"], context, _slot, _byte) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
