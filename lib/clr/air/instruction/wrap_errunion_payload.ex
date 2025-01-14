defmodule Clr.Air.Instruction.WrapErrunionPayload do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "wrap_errunion_payload <- 'wrap_errunion_payload' lparen type cs slotref rparen",
    wrap_errunion_payload: [export: true, post_traverse: :wrap_errunion_payload]
  )

  def wrap_errunion_payload(
        rest,
        [op, type, "wrap_errunion_payload"],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Block

  def analyze(%{type: {:errorable, errorset, _payload_type}, src: {src, _}}, slot, analysis) do
    {updated_payload, analysis} = Block.fetch!(analysis, src)
    Block.put_type(analysis, slot, {:errorable, errorset, updated_payload})
  end
end
