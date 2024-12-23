defmodule Clr.Air.Instruction.AddWrap do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[literal lvalue lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "add_wrap <- 'add_wrap' lparen (lineref / lvalue /literal) cs (lineref / lvalue / literal) rparen",
    add_wrap: [export: true, post_traverse: :add_wrap]
  )

  def add_wrap(rest, [rhs, lhs, "add_wrap"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
