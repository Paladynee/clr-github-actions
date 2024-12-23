defmodule Clr.Air.Instruction.Abs do
  defstruct [:src, :type]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs lparen rparen lvalue literal type]a)

  Pegasus.parser_from_string(
    "abs <- 'abs' lparen type cs argument rparen",
    abs: [export: true, post_traverse: :abs]
  )

  def abs(rest, [src, type, "abs"], context, _line, _bytes) do
    {rest, [%__MODULE__{src: src, type: type}], context}
  end
end
