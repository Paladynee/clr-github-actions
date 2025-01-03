defmodule Clr.Air.Instruction.ArrayElemVal do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument type literal lvalue slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "array_elem_val <- 'array_elem_val' lparen argument cs argument rparen",
    array_elem_val: [export: true, post_traverse: :array_elem_val]
  )

  def array_elem_val(rest, [slot, type, "array_elem_val"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: slot}], context}
  end
end
