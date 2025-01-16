defmodule Clr.Air.Instruction.Dbg do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[rparen lparen int colon]a)

  Pegasus.parser_from_string(
    """
    dbg <- trap / dbg_stmt / dbg_empty_stmt
    """,
    dbg: [export: true]
  )

  defmodule Trap do
    # represents a `trap` statement.
    defstruct []
  end

  Pegasus.parser_from_string(
    """
    trap <- trap_str 
    trap_str <- 'trap()'
    """,
    trap: [post_traverse: :trap],
    trap_str: [ignore: true]
  )

  def trap(rest, [], context, _, _) do
    {rest, [%Trap{}], context}
  end

  defmodule Stmt do
    defstruct [:loc]

    use Clr.Air.Instruction

    def analyze(%{loc: loc}, _slot, analysis) do
      %{analysis | loc: loc}
    end
  end

  Pegasus.parser_from_string(
    """
    dbg_stmt <- dbg_stmt_str lparen intrange rparen

    dbg_stmt_str <- 'dbg_stmt'

    intrange <- int colon int
    """,
    dbg_stmt: [post_traverse: :dbg_stmt],
    dbg_stmt_str: [ignore: true]
  )

  defp dbg_stmt(rest, [col, row], context, _slot, _bytes) do
    {rest, [%Stmt{loc: {row, col}}], context}
  end

  defmodule EmptyStmt do
    defstruct []
  end

  Pegasus.parser_from_string(
    """
    dbg_empty_stmt <- dbg_empty_stmt_str
    dbg_empty_stmt_str <- 'dbg_empty_stmt()'
    """,
    dbg_empty_stmt: [post_traverse: :dbg_empty_stmt],
    dbg_empty_stmt_str: [ignore: true]
  )

  def dbg_empty_stmt(rest, [], context, _, _) do
    {rest, [%EmptyStmt{}], context}
  end
end
