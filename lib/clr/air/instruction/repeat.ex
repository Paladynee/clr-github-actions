defmodule Clr.Air.Instruction.Repeat do
  defstruct [:goto]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "repeat <- 'repeat' lparen lineref rparen",
    repeat: [export: true, post_traverse: :repeat]
  )

  def repeat(rest, [line, "repeat"], context, _line, _bytes) do
    {rest, [%__MODULE__{goto: line}], context}
  end
end
