defmodule Clr.Air.Instruction.Ret do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "ret <- 'ret' lparen lvalue rparen",
    ret: [export: true, post_traverse: :ret]
  )

  def ret(rest, [value, "ret"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
