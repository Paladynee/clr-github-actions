defmodule Clr.Air.Instruction.Unreach do
  # represents a `unreach` statement

  defstruct []

  require Pegasus

  Pegasus.parser_from_string("unreach <- 'unreach()'",
    unreach: [export: true, post_traverse: :unreach]
  )

  def unreach(rest, ["unreach()"], context, _, _) do
    {rest, [%__MODULE__{}], context}
  end
end
