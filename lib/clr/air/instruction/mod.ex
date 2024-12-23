defmodule Clr.Air.Instruction.Mod do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "mod <- 'mod' lparen argument cs argument rparen",
    mod: [export: true, post_traverse: :mod]
  )

  def mod(rest, [rhs, lhs, "mod"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
