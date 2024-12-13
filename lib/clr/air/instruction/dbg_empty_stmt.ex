defmodule Clr.Air.Instruction.DbgEmptyStmt do
  # represents a `empty debug` statement

  defstruct []

  require Pegasus

  Pegasus.parser_from_string("dbg_empty_stmt <- 'dbg_empty_stmt()'",
    dbg_empty_stmt: [export: true, post_traverse: :dbg_empty_stmt]
  )

  def dbg_empty_stmt(rest, ["dbg_empty_stmt()"], context, _, _) do
    {rest, [%__MODULE__{}], context}
  end
end
