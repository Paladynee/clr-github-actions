defmodule Clr.Air.Instruction.Br do
  # represents a `break` statement

  defstruct [:goto, :value]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "br <- 'br' lparen lineref cs argument rparen",
    br: [export: true, post_traverse: :br]
  )

  def br(rest, [value, goto, "br"], context, _, _) do
    {rest, [%__MODULE__{goto: goto, value: value}], context}
  end
end
