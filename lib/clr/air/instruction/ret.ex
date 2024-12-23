defmodule Clr.Air.Instruction.Ret do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ret <- 'ret' lparen argument rparen",
    ret: [export: true, post_traverse: :ret]
  )

  def ret(rest, [value, "ret"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
