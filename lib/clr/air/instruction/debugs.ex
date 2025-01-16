defmodule Clr.Air.Instruction.Debugs do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    debugs <- trap
    """,
    debugs: [export: true]
  )

  defmodule Trap do
    # represents a `trap` statement.
    defstruct []
  end

  Pegasus.parser_from_string(
    """
    trap <- trap_str 
    trap_str <- 'trap()'
    """,
    trap: [post_traverse: :trap],
    trap_str: [ignore: true]
  )

  def trap(rest, [], context, _, _) do
    {rest, [%Trap{}], context}
  end
end
