defmodule Clr.Air.Instruction.RetLoad do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type lvalue]a)

  Pegasus.parser_from_string(
    "ret_load <- 'ret_load' lparen slotref rparen",
    ret_load: [export: true, post_traverse: :ret_load]
  )

  def ret_load(rest, [value, "ret_load"], context, _slot, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
