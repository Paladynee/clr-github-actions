defmodule Clr.Air.Instruction.PtrElemPtr do
  defstruct [:loc, :val, :type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ptr_elem_ptr <- 'ptr_elem_ptr' lparen type cs (lineref / literal) cs (lineref / lvalue / literal) rparen",
    ptr_elem_ptr: [export: true, post_traverse: :ptr_elem_ptr]
  )

  defp ptr_elem_ptr(rest, [val, loc, type, "ptr_elem_ptr"], context, _line, _byte) do
    {rest, [%__MODULE__{loc: loc, val: val, type: type}], context}
  end
end
