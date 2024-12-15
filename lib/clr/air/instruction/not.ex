defmodule Clr.Air.Instruction.Not do
  defstruct [:type, :operand]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "not <- 'not' lparen type cs (lineref / name) rparen",
    not: [export: true, post_traverse: :not_op]
  )

  def not_op(rest, [op, type, "not"], context, _line, _bytes) do
    {rest, [%__MODULE__{operand: op, type: type}], context}
  end
end
