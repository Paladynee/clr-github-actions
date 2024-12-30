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

  def arg(rest, [type, "arg"], context, _line, _byte) do
    {rest, [%__MODULE__{type: type}], context}
  end

  def arg(rest, [name, type, "arg"], context, _line, _byte) do
    {rest, [%__MODULE__{type: type, name: name}], context}
  end

  def analyze(%{type: type}, line, analysis), do: Analysis.put_type(analysis, line, type)
end
