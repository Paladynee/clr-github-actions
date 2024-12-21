defmodule Clr.Air.Instruction.IntFromBool do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs dquoted lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "int_from_bool <- 'int_from_bool' lparen (literal / lineref) rparen",
    int_from_bool: [export: true, post_traverse: :int_from_bool]
  )

  def int_from_bool(rest, [value, "int_from_bool"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
