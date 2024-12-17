defmodule Clr.Air.Instruction.Slice do
  defstruct [:type, :src, :len]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen langle rangle]a)

  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)

  Pegasus.parser_from_string(
    "slice <- 'slice' lparen type cs (lineref / literal) cs lineref rparen",
    slice: [export: true, post_traverse: :slice]
  )

  defp slice(rest, [len, src, type, "slice"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, src: src, len: len}], context}
  end
end
