defmodule Clr.Air.Instruction.Trap do
  # represents a `trap` statement

  defstruct []

  require Pegasus

  Pegasus.parser_from_string("trap <- 'trap()'", trap: [export: true, post_traverse: :trap])

  def trap(rest, ["trap()"], context, _, _) do
    {rest, [%__MODULE__{}], context}
  end
end
