defmodule Clr.Air.Instruction.GetUnionTag do
  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type literal]a)

  Pegasus.parser_from_string(
    "get_union_tag <- 'get_union_tag' lparen type cs slotref rparen",
    get_union_tag: [export: true, post_traverse: :get_union_tag]
  )

  def get_union_tag(rest, [loc, type, "get_union_tag"], context, _slot, _bytes) do
    {rest, [%__MODULE__{loc: loc, type: type}], context}
  end
end
