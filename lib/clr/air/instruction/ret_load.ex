defmodule Clr.Air.Instruction.RetLoad do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type lvalue]a)

  Pegasus.parser_from_string(
    "ret_load <- 'ret_load' lparen lineref rparen",
    ret_load: [export: true, post_traverse: :ret_load]
  )

  def ret_load(rest, [value, "ret_load"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
