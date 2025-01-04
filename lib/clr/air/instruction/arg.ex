defmodule Clr.Air.Instruction.Arg do
  use Clr.Air.Instruction

  defstruct [:type, :name]

  require Pegasus
  require Clr.Air
  alias Clr.Analysis

  Clr.Air.import(~w[type int cs dquoted lparen rparen]a)

  Pegasus.parser_from_string(
    "arg <- 'arg' lparen type (cs dquoted)? rparen",
    arg: [export: true, post_traverse: :arg]
  )

  def arg(rest, [type, "arg"], context, _slot, _byte) do
    {rest, [%__MODULE__{type: type}], context}
  end

  def arg(rest, [name, type, "arg"], context, _slot, _byte) do
    {rest, [%__MODULE__{type: type, name: name}], context}
  end

  def analyze(_instruction, slot, analysis) do
    # note that the slot of the arg instruction is ALWAYS the index of the
    # call type parameter.
    type = case Analysis.fetch_arg!(analysis, slot) do
      {:ptr, count, type, opts} ->
        # mark this as a passed argument, so that downstream we can remember
        # where it came from.
        {:ptr, count, type, Keyword.put(opts, :passed_as, slot)}
      other ->
        other
    end
    Analysis.put_type(analysis, slot, type)
  end
end
