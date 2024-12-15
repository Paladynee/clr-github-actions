defmodule Clr.Air.Instruction.RetAddr do
  defstruct []

  require Pegasus

  Pegasus.parser_from_string("ret_addr <- 'ret_addr()'",
    ret_addr: [export: true, post_traverse: :ret_addr]
  )

  def ret_addr(rest, ["ret_addr()"], context, _, _) do
    {rest, [%__MODULE__{}], context}
  end
end
