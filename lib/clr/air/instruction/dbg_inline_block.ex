defmodule Clr.Air.Instruction.DbgInlineBlock do
  defstruct [:type, :what, :code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Parser, [:codeblock])

  Clr.Air.import(
    Clr.Air.Base,
    ~w[clobbers name int tag cs squoted space colon lparen rparen langle rangle]a
  )

  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Literal, [:fn_literal])

  Pegasus.parser_from_string(
    "dbg_inline_block <- 'dbg_inline_block' lparen type cs fn_literal cs codeblock (space clobbers)? rparen",
    dbg_inline_block: [export: true, post_traverse: :dbg_inline_block]
  )

  defp dbg_inline_block(rest, [codeblock, fun, name, "dbg_inline_block"], context, _line, _bytes) do
    {rest, [%__MODULE__{code: codeblock, what: fun, type: name}], context}
  end

  defp dbg_inline_block(
         rest,
         [{:clobbers, clobbers}, codeblock, fun, name, "dbg_inline_block"],
         context,
         _line,
         _bytes
       ) do
    {rest, [%__MODULE__{code: codeblock, what: fun, type: name, clobbers: clobbers}], context}
  end
end
