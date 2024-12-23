defmodule Clr.Air.Instruction.StructFieldPtrIndex do
  defstruct [:type, :src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type int lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    struct_field_ptr_index <- instruction int lparen type cs lineref rparen
    instruction <- 'struct_field_ptr_index_'
    """,
    struct_field_ptr_index: [export: true, post_traverse: :struct_field_ptr_index],
    instruction: [ignore: true]
  )

  def struct_field_ptr_index(
        rest,
        [op, type, index],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type, index: index}], context}
  end
end
