defmodule Clr.Air.Instruction.RetSafe do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "ret_safe <- 'ret_safe' lparen lvalue rparen",
    ret_safe: [export: true, post_traverse: :ret_safe]
  )

  def ret_safe(rest, [value, "ret_safe"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
