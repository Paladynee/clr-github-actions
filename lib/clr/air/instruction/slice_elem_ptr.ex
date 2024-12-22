defmodule Clr.Air.Instruction.SliceElemPtr do
  defstruct [:type, :src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen langle rangle]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "slice_elem_ptr <- 'slice_elem_ptr' lparen type cs lineref cs (lineref / lvalue) rparen",
    slice_elem_ptr: [export: true, post_traverse: :slice_elem_ptr]
  )

  defp slice_elem_ptr(rest, [index, src, type, "slice_elem_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{index: index, src: src, type: type}], context}
  end
end
