defmodule Clr.Air.Instruction.Loop do
  defstruct [:type, :code]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[cs lparen rparen type codeblock]a)

  Pegasus.parser_from_string(
    "loop <- 'loop' lparen type cs codeblock rparen",
    loop: [export: true, post_traverse: :loop]
  )

  def loop(rest, [codeblock, type, "loop"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, code: codeblock}], context}
  end
end
