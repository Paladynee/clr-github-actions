defmodule Clr.Air.Instruction.RetSafe do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ret_safe <- 'ret_safe' lparen (lvalue / lineref / literal) rparen",
    ret_safe: [export: true, post_traverse: :ret_safe]
  )

  def ret_safe(rest, [value, "ret_safe"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
