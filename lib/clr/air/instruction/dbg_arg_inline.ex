defmodule Clr.Air.Instruction.DbgArgInline do
  defstruct [:val, :key]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[argument lineref cs dquoted lparen rparen lvalue literal]a)

  Pegasus.parser_from_string(
    "dbg_arg_inline <- 'dbg_arg_inline' lparen argument cs dquoted rparen",
    dbg_arg_inline: [export: true, post_traverse: :dbg_arg_inline]
  )

  def dbg_arg_inline(rest, [key, value, "dbg_arg_inline"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value, key: key}], context}
  end
end
