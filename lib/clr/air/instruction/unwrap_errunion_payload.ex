defmodule Clr.Air.Instruction.UnwrapErrunionPayload do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "unwrap_errunion_payload <- 'unwrap_errunion_payload' lparen type cs slotref rparen",
    unwrap_errunion_payload: [export: true, post_traverse: :unwrap_errunion_payload]
  )

  def unwrap_errunion_payload(
        rest,
        [src, type, "unwrap_errunion_payload"],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%__MODULE__{src: src, type: type}], context}
  end
end
