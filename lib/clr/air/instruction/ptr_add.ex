defmodule Clr.Air.Instruction.PtrAdd do
  defstruct [:type, :line, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[cs lineref lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "ptr_add <- 'ptr_add' lparen type cs lineref cs (lineref / lvalue /literal) rparen",
    ptr_add: [export: true, post_traverse: :ptr_add]
  )

  def ptr_add(rest, [val, line, type, "ptr_add"], context, _, _) do
    {rest, [%__MODULE__{val: val, line: line, type: type}], context}
  end
end
