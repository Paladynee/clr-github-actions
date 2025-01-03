defmodule Clr.Air.Instruction.RetPtr do
  defstruct [:type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "ret_ptr <- 'ret_ptr' lparen type rparen",
    ret_ptr: [export: true, post_traverse: :ret_ptr]
  )

  def ret_ptr(rest, [value, "ret_ptr"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: value}], context}
  end
end
