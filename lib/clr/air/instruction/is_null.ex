defmodule Clr.Air.Instruction.IsNull do
  defstruct [:line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref lparen rparen]a)

  Pegasus.parser_from_string(
    "is_null <- 'is_null' lparen lineref rparen",
    is_null: [export: true, post_traverse: :is_null]
  )

  def is_null(rest, [line, "is_null"], context, _line, _bytes) do
    {rest, [%__MODULE__{line: line}], context}
  end
end
