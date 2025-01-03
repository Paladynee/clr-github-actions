defmodule Clr.Air.Instruction.Repeat do
  defstruct [:goto]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref lparen rparen type]a)

  Pegasus.parser_from_string(
    "repeat <- 'repeat' lparen slotref rparen",
    repeat: [export: true, post_traverse: :repeat]
  )

  def repeat(rest, [slot, "repeat"], context, _slot, _bytes) do
    {rest, [%__MODULE__{goto: slot}], context}
  end
end
