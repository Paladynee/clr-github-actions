defmodule Clr.Air.Instruction.BitReverse do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue literal type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "bit_reverse <- 'bit_reverse' lparen type cs argument rparen",
    bit_reverse: [export: true, post_traverse: :bit_reverse]
  )

  def bit_reverse(rest, [src, type, "bit_reverse"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
