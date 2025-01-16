defmodule Clr.Air.Instruction.Casts do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    casts <- bitcast_instr
    """,
    casts: [export: true]
  )

  defmodule Bitcast do
    defstruct [:type, :src]

    use Clr.Air.Instruction
    alias Clr.Block

    def analyze(%{src: {src_slot, _}}, dst_slot, block) do
      case Block.fetch_up!(block, src_slot) do
        {type, block} ->
          Block.put_type(block, dst_slot, type)
      end
    end
  end

  Clr.Air.import(~w[argument lvalue type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    bitcast_instr <- bitcast lparen type cs argument rparen
    bitcast <- 'bitcast'
    """,
    bitcast_instr: [post_traverse: :bitcast],
    bitcast: [ignore: true]
  )

  def bitcast(rest, [slot, type], context, _slot, _bytes) do
    {rest, [%Bitcast{type: type, src: slot}], context}
  end
end
