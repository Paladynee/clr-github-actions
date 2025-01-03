defmodule Clr.Air.Instruction.UnionInit do
  defstruct [:val, :src]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref int cs lparen rparen langle rangle type]a)

  Pegasus.parser_from_string(
    "union_init <- 'union_init' lparen int cs slotref rparen",
    union_init: [export: true, post_traverse: :union_init]
  )

  defp union_init(rest, [src, val, "union_init"], context, _slot, _bytes) do
    {rest, [%__MODULE__{val: val, src: src}], context}
  end
end
