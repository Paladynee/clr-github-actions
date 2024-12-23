defmodule Clr.Air.Instruction.Repeat do
  defstruct [:goto]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref lparen rparen type]a)

  Pegasus.parser_from_string(
    "repeat <- 'repeat' lparen lineref rparen",
    repeat: [export: true, post_traverse: :repeat]
  )

  def repeat(rest, [line, "repeat"], context, _line, _bytes) do
    {rest, [%__MODULE__{goto: line}], context}
  end
end
