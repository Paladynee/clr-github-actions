defmodule Clr.Air.Instruction.UnwrapErrunionErr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "unwrap_errunion_err <- 'unwrap_errunion_err' lparen type cs slotref rparen",
    unwrap_errunion_err: [export: true, post_traverse: :unwrap_errunion_err]
  )

  def unwrap_errunion_err(rest, [src, type, "unwrap_errunion_err"], context, _slot, _bytes) do
    {rest, [%__MODULE__{src: src, type: type}], context}
  end
end
