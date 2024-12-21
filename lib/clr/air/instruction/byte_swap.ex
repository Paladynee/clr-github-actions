defmodule Clr.Air.Instruction.ByteSwap do
  defstruct [:type, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "byte_swap <- 'byte_swap' lparen type cs (lineref / lvalue) rparen",
    byte_swap: [export: true, post_traverse: :byte_swap]
  )

  def byte_swap(rest, [val, type, "byte_swap"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, val: val}], context}
  end
end
