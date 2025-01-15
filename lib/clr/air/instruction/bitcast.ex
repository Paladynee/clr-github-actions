defmodule Clr.Air.Instruction.Bitcast do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "bitcast <- 'bitcast' lparen type cs argument rparen",
    bitcast: [export: true, post_traverse: :bitcast]
  )

  def bitcast(rest, [slot, type, "bitcast"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, src: slot}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Block

  def analyze(%{type: {:ptr, _, _, _} = type, src: {src_slot, _}}, dst_slot, block) do
    case Block.fetch_up!(block, src_slot) do
      {{{:ptr, _, _, _}, meta}, block} ->
        Block.put_type(block, dst_slot, type, meta)
    end
  end
end
