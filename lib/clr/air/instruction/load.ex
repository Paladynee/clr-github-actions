defmodule Clr.Air.Instruction.Load do
  # takes a value from a pointer and puts into a vm slot.

  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type literal]a)

  Pegasus.parser_from_string(
    "load <- 'load' lparen type cs (lineref / literal) rparen",
    load: [export: true, post_traverse: :load]
  )

  def load(rest, [loc, type, "load"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Analysis

  def analyze(%{type: type}, line, analysis), do: Analysis.put_type(analysis, line, type)
end
