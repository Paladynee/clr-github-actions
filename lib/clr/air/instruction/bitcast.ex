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
  alias Clr.Function

  def analyze(%{type: {:ptr, count, base, opts}, src: {src_slot, _}}, dst_slot, analysis) do
    case Function.fetch!(analysis, src_slot) do
      {{:ptr, _, _, src_opts}, analysis} ->
        type = {:ptr, count, base, Keyword.merge(opts, src_opts)}
        Function.put_type(analysis, dst_slot, type)

        # don't deal with other cases yet.
    end
  end
end
