defmodule Clr.Air.Instruction.Controls do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument cs slotref lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    """
    controls <- return
    """,
    controls: [export: true]
  )

  # returns

  Pegasus.parser_from_string(
    """
    return <- ret_ptr
    ret_ptr <- 'ret_ptr' lparen type rparen
    """,
    ret_ptr: [export: true, post_traverse: :ret_ptr]
  )

  defmodule RetPtr do
    defstruct [:type]
  end

  def ret_ptr(rest, [value, "ret_ptr"], context, _slot, _bytes) do
    {rest, [%RetPtr{type: value}], context}
  end
end
