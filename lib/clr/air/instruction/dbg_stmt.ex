defmodule Clr.Air.Instruction.DbgStmt do
  defstruct [:range]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[int colon lparen rparen]a)

  Pegasus.parser_from_string(
    """
    dbg_stmt <- 'dbg_stmt' lparen intrange rparen

    intrange <- int colon int
    """,
    dbg_stmt: [export: true, post_traverse: :dbg_stmt]
  )

  defp dbg_stmt(rest, [right, left, "dbg_stmt"], context, _line, _bytes) do
    {rest, [%__MODULE__{range: left..right}], context}
  end
end
