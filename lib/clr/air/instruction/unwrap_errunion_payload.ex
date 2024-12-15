defmodule Clr.Air.Instruction.UnwrapErrunionPayload do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "unwrap_errunion_payload <- 'unwrap_errunion_payload' lparen type cs lineref rparen",
    unwrap_errunion_payload: [export: true, post_traverse: :unwrap_errunion_payload]
  )

  def unwrap_errunion_payload(
        rest,
        [src, type, "unwrap_errunion_payload"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: src, type: type}], context}
  end
end
