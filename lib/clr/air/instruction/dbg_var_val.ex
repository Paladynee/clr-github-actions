defmodule Clr.Air.Instruction.DbgVarVal do
  defstruct [:line, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref cs dquoted lparen rparen literal lvalue]a)

  Pegasus.parser_from_string(
    "dbg_var_val <- 'dbg_var_val' lparen argument cs dquoted rparen",
    dbg_var_val: [export: true, post_traverse: :dbg_var_val]
  )

  def dbg_var_val(rest, [value, line, "dbg_var_val"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value, line: line}], context}
  end
end
