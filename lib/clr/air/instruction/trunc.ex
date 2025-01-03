defmodule Clr.Air.Instruction.Trunc do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "trunc <- 'trunc' lparen type cs slotref rparen",
    trunc: [export: true, post_traverse: :trunc]
  )

  def trunc(rest, [src, type, "trunc"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
