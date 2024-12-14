defmodule Clr.Air.Instruction.DbgVarVal do
  defstruct [:line, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs dquoted lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:literal])

  Pegasus.parser_from_string(
    "dbg_var_val <- 'dbg_var_val' lparen (lineref / literal) cs dquoted rparen",
    dbg_var_val: [export: true, post_traverse: :dbg_var_val]
  )

  def dbg_var_val(rest, [value, line, "dbg_var_val"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value, line: line}], context}
  end
end
