defmodule Clr.Air.Instruction.UnwrapErrunionErrPtr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type]a)

  Pegasus.parser_from_string(
    "unwrap_errunion_err_ptr <- 'unwrap_errunion_err_ptr' lparen type cs slotref rparen",
    unwrap_errunion_err_ptr: [export: true, post_traverse: :unwrap_errunion_err_ptr]
  )

  def unwrap_errunion_err_ptr(
        rest,
        [op, type, "unwrap_errunion_err_ptr"],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
