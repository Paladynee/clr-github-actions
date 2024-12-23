defmodule Clr.Air.Instruction.WrapOptional do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "wrap_optional <- 'wrap_optional' lparen type cs lineref rparen",
    wrap_optional: [export: true, post_traverse: :wrap_optional]
  )

  def wrap_optional(
        rest,
        [op, type, "wrap_optional"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
