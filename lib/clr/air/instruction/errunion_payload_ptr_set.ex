defmodule Clr.Air.Instruction.ErrunionPayloadPtrSet do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs lparen rparen type literal]a)

  Pegasus.parser_from_string(
    "errunion_payload_ptr_set <- 'errunion_payload_ptr_set' lparen type cs lineref rparen",
    errunion_payload_ptr_set: [export: true, post_traverse: :errunion_payload_ptr_set]
  )

  def errunion_payload_ptr_set(
        rest,
        [loc, type, "errunion_payload_ptr_set"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{loc: loc, type: type}], context}
  end
end
