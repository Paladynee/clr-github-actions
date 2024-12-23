defmodule Clr.Air.Instruction.BitReverse do
  defstruct [:type, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "bit_reverse <- 'bit_reverse' lparen type cs (lineref / lvalue / literal) rparen",
    bit_reverse: [export: true, post_traverse: :bit_reverse]
  )

  def bit_reverse(rest, [src, type, "bit_reverse"], context, _line, _bytes) do
    {rest, [%__MODULE__{type: type, src: src}], context}
  end
end
