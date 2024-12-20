defmodule Clr.Air.Instruction.WrapErrunionPayload do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "wrap_errunion_payload <- 'wrap_errunion_payload' lparen type cs (lineref / name) rparen",
    wrap_errunion_payload: [export: true, post_traverse: :wrap_errunion_payload]
  )

  def wrap_errunion_payload(
        rest,
        [op, type, "wrap_errunion_payload"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
