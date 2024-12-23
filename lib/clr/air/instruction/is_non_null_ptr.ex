defmodule Clr.Air.Instruction.IsNonNullPtr do
  defstruct [:line]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[lineref lparen rparen literal]a)

  Pegasus.parser_from_string(
    "is_non_null_ptr <- 'is_non_null_ptr' lparen (lineref / literal) rparen",
    is_non_null_ptr: [export: true, post_traverse: :is_non_null_ptr]
  )

  def is_non_null_ptr(rest, [line, "is_non_null_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{line: line}], context}
  end
end
