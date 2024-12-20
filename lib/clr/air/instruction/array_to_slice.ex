defmodule Clr.Air.Instruction.ArrayToSlice do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "array_to_slice <- 'array_to_slice' lparen type cs (lineref / name) rparen",
    array_to_slice: [export: true, post_traverse: :array_to_slice]
  )

  def array_to_slice(rest, [line, type, "array_to_slice"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, src: line}], context}
  end
end
