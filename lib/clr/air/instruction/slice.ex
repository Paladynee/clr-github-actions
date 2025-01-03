defmodule Clr.Air.Instruction.Slice do
  defstruct [:type, :src, :len]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen langle rangle type literal]a)

  Pegasus.parser_from_string(
    "slice <- 'slice' lparen type cs (slotref / literal) cs slotref rparen",
    slice: [export: true, post_traverse: :slice]
  )

  defp slice(rest, [len, src, type, "slice"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: src, len: len}], context}
  end
end
