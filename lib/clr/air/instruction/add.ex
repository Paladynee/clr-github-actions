defmodule Clr.Air.Instruction.Add do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref literal lvalue cs lparen rparen]a)

  Pegasus.parser_from_string(
    "add <- 'add' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) rparen",
    add: [export: true, post_traverse: :add]
  )

  def add(rest, [rhs, lhs, "add"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
