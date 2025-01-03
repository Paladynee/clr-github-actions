defmodule Clr.Air.Instruction.Intcast do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type]a)

  Pegasus.parser_from_string(
    "intcast <- 'intcast' lparen type cs slotref rparen",
    intcast: [export: true, post_traverse: :intcast]
  )

  def intcast(rest, [src, type, "intcast"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
