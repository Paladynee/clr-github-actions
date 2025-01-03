defmodule Clr.Air.Instruction.ArrayToSlice do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "array_to_slice <- 'array_to_slice' lparen type cs slotref rparen",
    array_to_slice: [export: true, post_traverse: :array_to_slice]
  )

  def array_to_slice(rest, [slot, type, "array_to_slice"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: slot}], context}
  end
end
