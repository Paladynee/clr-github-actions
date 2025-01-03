defmodule Clr.Air.Instruction.SliceElemPtr do
  defstruct [:type, :src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument slotref cs lparen rparen langle rangle type lvalue literal]a)

  Pegasus.parser_from_string(
    "slice_elem_ptr <- 'slice_elem_ptr' lparen type cs slotref cs argument rparen",
    slice_elem_ptr: [export: true, post_traverse: :slice_elem_ptr]
  )

  defp slice_elem_ptr(rest, [index, src, type, "slice_elem_ptr"], context, _slot, _bytes) do
    {rest, [%__MODULE__{index: index, src: src, type: type}], context}
  end
end
