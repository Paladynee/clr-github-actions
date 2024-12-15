defmodule Clr.Air.Instruction.IsNonErr do
  defstruct [:line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref lparen rparen]a)

  Pegasus.parser_from_string(
    "is_non_err <- 'is_non_err' lparen lineref rparen",
    is_non_err: [export: true, post_traverse: :is_non_err]
  )

  def is_non_err(rest, [line, "is_non_err"], context, _line, _bytes) do
    {rest, [%__MODULE__{line: line}], context}
  end
end
