defmodule Clr.Air.Instruction.Not do
  defstruct [:type, :operand]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "not <- 'not' lparen type cs lineref rparen",
    not: [export: true, post_traverse: :not_op]
  )

  def not_op(rest, [op, type, "not"], context, _line, _bytes) do
    {rest, [%__MODULE__{operand: op, type: type}], context}
  end
end
