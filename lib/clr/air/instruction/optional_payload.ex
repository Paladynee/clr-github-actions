defmodule Clr.Air.Instruction.OptionalPayload do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "optional_payload <- 'optional_payload' lparen type cs lineref rparen",
    optional_payload: [export: true, post_traverse: :optional_payload]
  )

  def optional_payload(rest, [loc, type, "optional_payload"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end
end
