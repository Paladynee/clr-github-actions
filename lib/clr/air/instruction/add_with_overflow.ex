defmodule Clr.Air.Instruction.AddWithOverflow do
  defstruct [:type, :lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument type lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "add_with_overflow <- 'add_with_overflow' lparen type cs argument cs argument rparen",
    add_with_overflow: [export: true, post_traverse: :add_with_overflow]
  )

  def add_with_overflow(rest, [rhs, lhs, type, "add_with_overflow"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs, type: type}], context}
  end
end
