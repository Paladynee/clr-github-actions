defmodule Clr.Air.Instruction.SliceLen do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen langle rangle]a)

  Pegasus.parser_from_string(
    "slice_len <- 'slice_len' lparen type cs slotref rparen",
    slice_len: [export: true, post_traverse: :slice_len]
  )

  defp slice_len(rest, [src, type, "slice_len"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
