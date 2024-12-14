defmodule Clr.Air.Instruction.SliceElemVal do
  defstruct [:src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen langle rangle]a)

  Pegasus.parser_from_string(
    "slice_elem_val <- 'slice_elem_val' lparen lineref cs lineref rparen",
    slice_elem_val: [export: true, post_traverse: :slice_elem_val]
  )

  defp slice_elem_val(rest, [index, src, "slice_elem_val"], context, _line, _bytes) do
    {rest, [%__MODULE__{index: index, src: src}], context}
  end
end
