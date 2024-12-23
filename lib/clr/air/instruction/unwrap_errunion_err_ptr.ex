defmodule Clr.Air.Instruction.UnwrapErrunionErrPtr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "unwrap_errunion_err_ptr <- 'unwrap_errunion_err_ptr' lparen type cs (lineref / name) rparen",
    unwrap_errunion_err_ptr: [export: true, post_traverse: :unwrap_errunion_err_ptr]
  )

  def unwrap_errunion_err_ptr(
        rest,
        [op, type, "unwrap_errunion_err_ptr"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
