defmodule Clr.Air.Instruction.Sub do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen lvalue literal]a)

  Pegasus.parser_from_string(
    "sub <- 'sub' lparen argument cs argument rparen",
    sub: [export: true, post_traverse: :sub]
  )

  def sub(rest, [rhs, lhs, "sub"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
