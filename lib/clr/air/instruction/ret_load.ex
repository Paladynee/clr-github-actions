defmodule Clr.Air.Instruction.RetLoad do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "ret_load <- 'ret_load' lparen lineref rparen",
    ret_load: [export: true, post_traverse: :ret_load]
  )

  def ret_load(rest, [value, "ret_load"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
