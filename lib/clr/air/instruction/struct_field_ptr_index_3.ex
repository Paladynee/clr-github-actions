defmodule Clr.Air.Instruction.StructFieldPtrIndex3 do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "struct_field_ptr_index_3 <- 'struct_field_ptr_index_3' lparen type cs lineref rparen",
    struct_field_ptr_index_3: [export: true, post_traverse: :struct_field_ptr_index_3]
  )

  def struct_field_ptr_index_3(
        rest,
        [op, type, "struct_field_ptr_index_3"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
