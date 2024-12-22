defmodule Clr.Air.Instruction.ArrayElemVal do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])
  Clr.Air.import(Clr.Air.Literal, ~w[literal]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Pegasus.parser_from_string(
    "array_elem_val <- 'array_elem_val' lparen (lineref / literal) cs (lineref / lvalue / literal) rparen",
    array_elem_val: [export: true, post_traverse: :array_elem_val]
  )

  def array_elem_val(rest, [line, type, "array_elem_val"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, src: line}], context}
  end
end
