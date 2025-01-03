defmodule Clr.Air.Instruction.DbgStmt do
  defstruct [:row, :col]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[int colon lparen rparen]a)

  Pegasus.parser_from_string(
    """
    dbg_stmt <- 'dbg_stmt' lparen intrange rparen

    intrange <- int colon int
    """,
    dbg_stmt: [export: true, post_traverse: :dbg_stmt]
  )

  defp dbg_stmt(rest, [col, row, "dbg_stmt"], context, _slot, _bytes) do
    {rest, [%__MODULE__{row: row, col: col}], context}
  end

  use Clr.Air.Instruction

  def analyze(%__MODULE__{row: row, col: col}, _slot, analysis) do
    %{analysis | row: row, col: col}
  end
end
