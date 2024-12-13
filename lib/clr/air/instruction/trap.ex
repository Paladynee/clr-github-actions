defmodule Clr.Air.Instruction.Trap do
  # represents a `break` statement

  defstruct []

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)

  Pegasus.parser_from_string("trap <- 'trap()'", trap: [export: true, post_traverse: :trap])

  def trap(rest, ["trap()"], context, _, _) do
    {rest, [%__MODULE__{}], context}
  end
end
