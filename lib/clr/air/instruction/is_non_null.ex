defmodule Clr.Air.Instruction.IsNonNull do
  defstruct [:line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref lparen rparen]a)

  Pegasus.parser_from_string(
    "is_non_null <- 'is_non_null' lparen lineref rparen",
    is_non_null: [export: true, post_traverse: :is_non_null]
  )

  def is_non_null(rest, [line, "is_non_null"], context, _line, _bytes) do
    {rest, [%__MODULE__{line: line}], context}
  end
end
