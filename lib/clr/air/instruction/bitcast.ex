defmodule Clr.Air.Instruction.Bitcast do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "bitcast <- 'bitcast' lparen type cs argument rparen",
    bitcast: [export: true, post_traverse: :bitcast]
  )

  def bitcast(rest, [line, type, "bitcast"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, src: line}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Analysis

  def analyze(%{type: {:ptr, count, base, opts}, src: {src_line, _}}, dst_line, analysis) do
    case Analysis.fetch!(analysis, src_line) do
      {:ptr, _, _, src_opts} ->
        type = {:ptr, count, base, Keyword.merge(opts, src_opts)}
        Analysis.put_type(analysis, dst_line, type)

        # don't deal with other cases yet.
    end
  end
end
