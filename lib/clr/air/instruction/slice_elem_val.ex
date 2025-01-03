defmodule Clr.Air.Instruction.SliceElemVal do
  defstruct [:src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref argument cs lparen rparen langle rangle lvalue literal]a)

  Pegasus.parser_from_string(
    "slice_elem_val <- 'slice_elem_val' lparen slotref cs argument rparen",
    slice_elem_val: [export: true, post_traverse: :slice_elem_val]
  )

  defp slice_elem_val(rest, [index, src, "slice_elem_val"], context, _slot, _bytes) do
    {rest, [%__MODULE__{index: index, src: src}], context}
  end
end
