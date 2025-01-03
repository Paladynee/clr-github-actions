defmodule Clr.Air.Instruction.WrapErrunionErr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type slotref cs lparen rparen]a)

  Pegasus.parser_from_string(
    "wrap_errunion_err <- 'wrap_errunion_err' lparen type cs slotref rparen",
    wrap_errunion_err: [export: true, post_traverse: :wrap_errunion_err]
  )

  def wrap_errunion_err(
        rest,
        [op, type, "wrap_errunion_err"],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
