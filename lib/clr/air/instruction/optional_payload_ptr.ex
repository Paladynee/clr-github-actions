defmodule Clr.Air.Instruction.OptionalPayloadPtr do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type literal lvalue]a)

  Pegasus.parser_from_string(
    "optional_payload_ptr <- 'optional_payload_ptr' lparen type cs (lineref / literal / lvalue) rparen",
    optional_payload_ptr: [export: true, post_traverse: :optional_payload_ptr]
  )

  def optional_payload_ptr(rest, [loc, type, "optional_payload_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end
end
