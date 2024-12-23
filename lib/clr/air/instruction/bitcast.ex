defmodule Clr.Air.Instruction.Bitcast do
  defstruct [:type, :line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lvalue type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "bitcast <- 'bitcast' lparen type cs (lineref / lvalue) rparen",
    bitcast: [export: true, post_traverse: :bitcast]
  )

  def bitcast(rest, [line, type, "bitcast"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, line: line}], context}
  end
end
