defmodule Clr.Air.Instruction.Dbg do
  require Pegasus

  alias Clr.Air

  require Air

  import Clr.Air.Lvalue

  Air.import(
    ~w[rparen lparen int colon type cs codeblock clobbers space fn_literal literal slotref dquoted argument]a
  )

  Pegasus.parser_from_string(
    """
    dbg <- trap / dbg_stmt / dbg_empty_stmt / dbg_inline_block / dbg_var_ptr / dbg_var_val / dbg_arg_inline / breakpoint
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

  defp dbg_stmt(rest, [col, row], context, _loc, _bytes) do
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

  defmodule InlineBlock do
    defstruct [:type, :what, :code, clobbers: []]
  end

  Pegasus.parser_from_string(
    """
    dbg_inline_block <- dbg_inline_block_str lparen type cs fn_literal cs codeblock (space clobbers)? rparen
    dbg_inline_block_str <- 'dbg_inline_block'
    """,
    dbg_inline_block: [post_traverse: :dbg_inline_block],
    dbg_inline_block_str: [ignore: true]
  )

  defp dbg_inline_block(rest, [codeblock, fun, name], context, _loc, _bytes) do
    {rest, [%InlineBlock{code: codeblock, what: fun, type: name}], context}
  end

  defp dbg_inline_block(
         rest,
         [{:clobbers, clobbers}, codeblock, fun, name],
         context,
         _slot,
         _bytes
       ) do
    {rest, [%InlineBlock{code: codeblock, what: fun, type: name, clobbers: clobbers}], context}
  end

  defmodule VarPtr do
    defstruct [:src, :val]
  end

  Pegasus.parser_from_string(
    """
    dbg_var_ptr <- dbg_var_ptr_str lparen (slotref / literal) cs dquoted rparen
    dbg_var_ptr_str <- 'dbg_var_ptr'
    """,
    dbg_var_ptr: [post_traverse: :dbg_var_ptr],
    dbg_var_ptr_str: [ignore: true]
  )

  def dbg_var_ptr(rest, [value, src], context, _loc, _bytes) do
    {rest, [%VarPtr{val: value, src: src}], context}
  end

  defmodule VarVal do
    defstruct [:src, :val]
  end

  Pegasus.parser_from_string(
    """
    dbg_var_val <- dbg_var_val_str lparen argument cs dquoted rparen
    dbg_var_val_str <- 'dbg_var_val' 
    """,
    dbg_var_val: [post_traverse: :dbg_var_val],
    dbg_var_val_str: [ignore: true]
  )

  def dbg_var_val(rest, [value, src], context, _loc, _bytes) do
    {rest, [%VarVal{val: value, src: src}], context}
  end

  defmodule ArgInline do
    defstruct [:val, :key]
  end

  Pegasus.parser_from_string(
    """
    dbg_arg_inline <- dbg_arg_inline_str lparen argument cs dquoted rparen
    dbg_arg_inline_str <- 'dbg_arg_inline'
    """,
    dbg_arg_inline: [export: true, post_traverse: :dbg_arg_inline],
    dbg_arg_inline_str: [ignore: true]
  )

  def dbg_arg_inline(rest, [key, value], context, _loc, _bytes) do
    {rest, [%ArgInline{val: value, key: key}], context}
  end

  Air.unimplemented(:breakpoint)
end
