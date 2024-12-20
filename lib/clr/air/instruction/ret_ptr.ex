defmodule Clr.Air.Instruction.RetPtr do
  defstruct [:type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    "ret_ptr <- 'ret_ptr' lparen type  rparen",
    ret_ptr: [export: true, post_traverse: :ret_ptr]
  )

  def ret_ptr(rest, [value, "ret_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: value}], context}
  end
end
