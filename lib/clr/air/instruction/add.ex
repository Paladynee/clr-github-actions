defmodule Clr.Air.Instruction.Add do
  defstruct [:lhs, :rhs]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)

  Pegasus.parser_from_string(
    "add <- 'add' lparen lineref cs (lineref / name) rparen",
    add: [export: true, post_traverse: :add]
  )

  def add(rest, [rhs, lhs, "add"], context, _line, _bytes) do
    {rest, [%__MODULE__{lhs: lhs, rhs: rhs}], context}
  end
end
