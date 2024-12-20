defmodule Clr.Air.Instruction.WrapErrunionErr do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)

  Pegasus.parser_from_string(
    "wrap_errunion_err <- 'wrap_errunion_err' lparen type cs (lineref / name) rparen",
    wrap_errunion_err: [export: true, post_traverse: :wrap_errunion_err]
  )

  def wrap_errunion_err(
        rest,
        [op, type, "wrap_errunion_err"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{src: op, type: type}], context}
  end
end
