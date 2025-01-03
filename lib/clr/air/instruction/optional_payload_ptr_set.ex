defmodule Clr.Air.Instruction.OptionalPayloadPtrSet do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument slotref cs lparen rparen type literal lvalue]a)

  Pegasus.parser_from_string(
    "optional_payload_ptr_set <- 'optional_payload_ptr_set' lparen type cs argument rparen",
    optional_payload_ptr_set: [export: true, post_traverse: :optional_payload_ptr_set]
  )

  def optional_payload_ptr_set(
        rest,
        [loc, type, "optional_payload_ptr_set"],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end
end
