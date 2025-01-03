defmodule Clr.Air.Instruction.SlicePtr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen langle rangle]a)

  Pegasus.parser_from_string(
    "slice_ptr <- 'slice_ptr' lparen type cs slotref rparen",
    slice_ptr: [export: true, post_traverse: :slice_ptr]
  )

  defp slice_ptr(rest, [src, type, "slice_ptr"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
