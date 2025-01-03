defmodule Clr.Air.Instruction.IntFromPtr do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs dquoted lparen rparen literal]a)

  Pegasus.parser_from_string(
    "int_from_ptr <- 'int_from_ptr' lparen (literal / slotref) rparen",
    int_from_ptr: [export: true, post_traverse: :int_from_ptr]
  )

  def int_from_ptr(rest, [value, "int_from_ptr"], context, _slot, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
