defmodule Clr.Air.Instruction.Bitcast do
  defstruct [:type, :line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "bitcast <- 'bitcast' lparen type cs lineref rparen",
    bitcast: [export: true, post_traverse: :bitcast]
  )

  def bitcast(rest, [line, type, "bitcast"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, line: line}], context}
  end
end
