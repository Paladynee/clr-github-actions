defmodule Clr.Air.Instruction.Br do
  # represents a `break` statement

  defstruct [:goto, :value]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lvalue literal slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "br <- 'br' lparen slotref cs argument rparen",
    br: [export: true, post_traverse: :br]
  )

  def br(rest, [value, goto, "br"], context, _, _) do
    {rest, [%__MODULE__{goto: goto, value: value}], context}
  end
end
