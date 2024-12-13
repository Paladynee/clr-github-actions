defmodule Clr.Air.Instruction.PtrAdd do
  defstruct [:type, :line, :val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[name cs lineref lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])

  Pegasus.parser_from_string(
    "ptr_add <- 'ptr_add' lparen type cs lineref cs (lineref / name) rparen",
    ptr_add: [export: true, post_traverse: :ptr_add]
  )

  def ptr_add(rest, [val, line, type, "ptr_add"], context, _, _) do
    {rest, [%__MODULE__{val: val, line: line, type: type}], context}
  end
end
