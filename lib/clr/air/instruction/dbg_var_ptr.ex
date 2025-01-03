defmodule Clr.Air.Instruction.DbgVarPtr do
  defstruct [:src, :val]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[slotref cs dquoted lparen rparen literal]a)

  Pegasus.parser_from_string(
    "dbg_var_ptr <- 'dbg_var_ptr' lparen (slotref / literal) cs dquoted rparen",
    dbg_var_ptr: [export: true, post_traverse: :dbg_var_ptr]
  )

  def dbg_var_ptr(rest, [value, src, "dbg_var_ptr"], context, _slot, _bytes) do
    {rest, [%__MODULE__{val: value, src: src}], context}
  end
end
