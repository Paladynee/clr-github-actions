defmodule Clr.Air.Instruction.OptionalPayloadPtrSet do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "optional_payload_ptr_set <- 'optional_payload_ptr_set' lparen type cs (lineref / literal / lvalue) rparen",
    optional_payload_ptr_set: [export: true, post_traverse: :optional_payload_ptr_set]
  )

  def optional_payload_ptr_set(
        rest,
        [loc, type, "optional_payload_ptr_set"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end
end
