defmodule Clr.Air.Instruction.WrapErrunionPayload do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "wrap_errunion_payload <- 'wrap_errunion_payload' lparen type cs lineref rparen",
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

  use Clr.Air.Instruction
  alias Clr.Analysis

  def analyze(%{type: {:errorable, errorset, _payload_type}, src: {src, _}}, line, analysis) do
    updated_payload = Analysis.fetch!(analysis, src)
    Analysis.put_type(analysis, line, {:errorable, errorset, updated_payload})
  end
end
