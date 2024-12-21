defmodule Clr.Air.Instruction.ErrorName do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs dquoted lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "error_name <- 'error_name' lparen (literal / lineref) rparen",
    error_name: [export: true, post_traverse: :error_name]
  )

  def error_name(rest, [value, "error_name"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
