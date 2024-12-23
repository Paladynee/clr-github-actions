defmodule Clr.Air.Instruction.SlicePtr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref cs lparen rparen langle rangle]a)

  Pegasus.parser_from_string(
    "slice_ptr <- 'slice_ptr' lparen type cs lineref rparen",
    slice_ptr: [export: true, post_traverse: :slice_ptr]
  )

  defp slice_ptr(rest, [src, type, "slice_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
