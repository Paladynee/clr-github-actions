defmodule Clr.Air.Instruction.PtrSliceLenPtr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument lineref cs lparen rparen lvalue type]a)

  Pegasus.parser_from_string(
    "ptr_slice_len_ptr <- 'ptr_slice_len_ptr' lparen type cs argument rparen",
    ptr_slice_len_ptr: [export: true, post_traverse: :ptr_slice_len_ptr]
  )

  defp ptr_slice_len_ptr(rest, [src, type, "ptr_slice_len_ptr"], context, _line, _byte) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
