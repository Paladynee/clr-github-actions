defmodule Clr.Air.Instruction.Clz do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref literal lvalue cs lparen rparen]a)

  Pegasus.parser_from_string(
    "clz <- 'clz' lparen argument cs argument rparen",
    clz: [export: true, post_traverse: :clz]
  )

  def clz(rest, [rhs, lhs, "clz"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
