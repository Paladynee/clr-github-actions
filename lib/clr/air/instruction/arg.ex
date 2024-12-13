defmodule Clr.Air.Instruction.Arg do
  defstruct [:type, :name]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[int cs dquoted lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "arg <- 'arg' lparen type cs dquoted rparen",
    arg: [export: true, post_traverse: :arg]
  )

  def arg(rest, [name, type, "arg"], context, _line, _byte) do
    {rest, [%__MODULE__{type: type, name: name}], context}
  end
end
