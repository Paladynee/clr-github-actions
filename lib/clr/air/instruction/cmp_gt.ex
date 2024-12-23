defmodule Clr.Air.Instruction.CmpGt do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "cmp_gt <- 'cmp_gt' lparen lineref cs (lineref / lvalue / literal) rparen",
    cmp_gt: [export: true, post_traverse: :cmp_gt]
  )

  def cmp_gt(rest, [rhs, lhs, "cmp_gt"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
