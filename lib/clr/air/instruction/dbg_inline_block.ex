defmodule Clr.Air.Instruction.DbgInlineBlock do
  defstruct [:type, :what, :code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[codeblock clobbers int cs squoted space colon lparen rparen langle rangle type fn_literal]a
  )

  Pegasus.parser_from_string(
    "dbg_inline_block <- 'dbg_inline_block' lparen type cs fn_literal cs codeblock (space clobbers)? rparen",
    dbg_inline_block: [export: true, post_traverse: :dbg_inline_block]
  )

  defp dbg_inline_block(rest, [codeblock, fun, name, "dbg_inline_block"], context, _slot, _bytes) do
    {rest, [%__MODULE__{code: codeblock, what: fun, type: name}], context}
  end

  defp dbg_inline_block(
         rest,
         [{:clobbers, clobbers}, codeblock, fun, name, "dbg_inline_block"],
         context,
         _slot,
         _bytes
       ) do
    {rest, [%__MODULE__{code: codeblock, what: fun, type: name, clobbers: clobbers}], context}
  end
end
