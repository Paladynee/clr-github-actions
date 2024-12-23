defmodule Clr.Air.Instruction.StructFieldPtr do
  defstruct [:src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref int cs lparen rparen]a)

  Pegasus.parser_from_string(
    "struct_field_ptr <- 'struct_field_ptr' lparen lineref cs int rparen",
    struct_field_ptr: [export: true, post_traverse: :struct_field_ptr]
  )

  def struct_field_ptr(rest, [index, src, "struct_field_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{src: src, index: index}], context}
  end
end
