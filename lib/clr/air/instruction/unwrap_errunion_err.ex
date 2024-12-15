defmodule Clr.Air.Instruction.UnwrapErrunionErr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "unwrap_errunion_err <- 'unwrap_errunion_err' lparen type cs lineref rparen",
    unwrap_errunion_err: [export: true, post_traverse: :unwrap_errunion_err]
  )

  def unwrap_errunion_err(rest, [src, type, "unwrap_errunion_err"], context, _line, _bytes) do
    {rest, [%__MODULE__{src: src, type: type}], context}
  end
end
