defmodule Clr.Air.Instruction.Block do
  defstruct [:type, :code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type codeblock clobbers cs space lparen rparen]a)

  Pegasus.parser_from_string(
    "block <- 'block' lparen type cs codeblock (space clobbers)? rparen",
    block: [export: true, post_traverse: :block]
  )

  def block(rest, [codeblock, type, "block"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, code: codeblock}], context}
  end

  def block(rest, [{:clobbers, clobbers}, codeblock, type, "block"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, code: codeblock, clobbers: clobbers}], context}
  end
end
