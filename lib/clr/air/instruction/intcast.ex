defmodule Clr.Air.Instruction.Intcast do
  defstruct [:type, :line]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type]a)

  Pegasus.parser_from_string(
    "intcast <- 'intcast' lparen type cs lineref rparen",
    intcast: [export: true, post_traverse: :intcast]
  )

  def intcast(rest, [line, type, "intcast"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, line: line}], context}
  end
end
